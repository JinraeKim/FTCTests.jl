using FTCTests
const FTC = FaultTolerantControl
using LinearAlgebra
using Plots


function compute_minHSV(lambda, num=1)
    # Quadcopter state space model
    gc = 9.81
    m = 0.65
    l = 0.023
    k = 31.1e-5
    b = 7.5e-7
    J = Diagonal([7.5e-3, 7.4e-3, 1.3e-2])
    Jinv = inv(J)
    A = [zeros(3, 3) Matrix(I, 3, 3) zeros(3, 3) zeros(3, 3);
    zeros(3, 3) zeros(3, 3) zeros(3, 3) zeros(3, 3);
    zeros(3, 3) zeros(3, 3) zeros(3, 3) zeros(3, 3);
    zeros(3, 3) zeros(3, 3) Matrix(I, 3, 3) zeros(3, 3)]
    B = zeros(12, 4)
    for i = 1:12
        for j = 1:4
            if i == 5
                if j == 1
                    B[i, j] = -l*k/J[2, 2]
                elseif j == 3
                    B[i, j] = l*k/J[2, 2]
                end
            elseif i == 4
                if j == 2
                    B[i, j] = -l*k/J[1, 1]
                elseif j == 4
                    B[i, j] = l*k/J[1, 1]
                end
            elseif i == 6
                if j == 1 || j == 3
                    B[i, j] = -b/J[3, 3]
                elseif j == 2 || j == 4
                    B[i, j] = b/J[3, 3]
                end
            elseif i == 9
                if j == 1 || j == 2 || j == 3 || j == 4
                    B[i, j] = k/m
                end
            else
                B[i, j] = 0
            end
        end
    end
    C = [Matrix(I, 3, 3) zeros(3, 3) zeros(3, 3) zeros(3, 3);
    zeros(3, 3) Matrix(I, 3, 3) zeros(3, 3) zeros(3, 3);
    zeros(3, 3) zeros(3, 3) zeros(3, 3) Matrix(I, 3, 3)]

    u_ss = sqrt(m*gc/4/k) * ones(4,)
    T(x) = [-sin(x[2]) 0 1;
            cos(x[2])*sin(x[3]) cos(x[3]) 0;
            cos(x[2])*cos(x[3]) -sin(x[3]) 0]
    R(x) = [cos(x[2])*cos(x[3]) sin(x[3])*sin(x[2]) -sin(x[2]);
            cos(x[3])*sin(x[2])*sin(x[1])-sin(x[3])*cos(x[1]) sin(x[3])*sin(x[2])*sin(x[1])+cos(x[3])*cos(x[1]) cos(x[2])*sin(x[1]);
            cos(x[3])*sin(x[2])*cos(x[1])-sin(x[3])*sin(x[1]) sin(x[3])*sin(x[2])*cos(x[1])+cos(x[3])*sin(x[1]) cos(x[2])*cos(x[1])]
    F(x) = vec([
        T(x) * x[4:6]
        Jinv * cross(-x[4:6], J * x[4:6])
        -cross(x[4:6], x[7:9]) + gc * R(x)' * [0; 0; 1]
        R(x) * x[7:9]
    ])

    if num == 1
        eff = Diagonal([lambda, 1, 1, 1])
    elseif num == 2
        eff = Diagonal([1, lambda, 1, 1])
    elseif num == 3
        eff = Diagonal([1, 1, lambda, 1])
    elseif num == 4
        eff = Diagonal([1, 1, 1, lambda])
    else
        error("Choose fauly actuator number")
    end

    f(x, u, p, t) = A*x + F(x) + B*(eff * u + u_ss).^2
    g(x, u, p, t) = C*x

	# System dimension
	n = size(A)[1]
	m = size(B)[2]
	l = size(C)[1]

    # Initial settings
    x0 = zeros(n,)
    u0 = zeros(m,)
    dt = 0.001
    tf = 1.0
    pr = zeros(4, 1)

    Wc = FTC.empirical_gramian(f, g, m, n, l; opt=:c, dt=dt, tf=tf, pr=pr, xs=x0, us=u0)
    Wo = FTC.empirical_gramian(f, g, m, n, l; opt=:o, dt=dt, tf=tf, pr=pr, xs=x0, us=u0)
	minHSV = FTC.min_HSV(Wc, Wo)
end

function plotting()
    lambda = range(0, 1, 20)
    HSVs = []
    for i = 1:length(lambda)
        HSVs = push!(HSVs, compute_minHSV(collect(lambda)[i], 2))
    end
    plot(lambda,
        HSVs,
        xlabel = "Actuator effectiveness",
        ylabel = "Minimum HSVs",
        label = nothing,
    )
end
nothing