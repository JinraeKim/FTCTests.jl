using FTCTests
const FTC = FaultTolerantControl
using LinearAlgebra
using Plots


function compute_minHSV(eff)
    A = [-1.01887 0.90506 -0.00215;
    0.82225 -1.07741 -0.17555;
    0 0 -1]
    B = [0 0 1]'
    C = Matrix(I, 3, 3)

    f(x, u, p, t) = A*x + B*(eff * u)
    g(x, u, p, t) = C*x

	# System dimension
	n = size(A)[1]
	m = 1
	l = size(C)[1]

    # Initial settings
    x0 = zeros(n,)
    u0 = zeros(m,)
    dt = 0.001
    tf = 1.0
    pr = zeros(3, 1)

    Wc = empirical_gramian(f, g, m, n, l; opt=:c, dt=dt, tf=tf, pr=pr, xs=x0, us=u0)
    Wo = empirical_gramian(f, g, m, n, l; opt=:o, dt=dt, tf=tf, pr=pr, xs=x0, us=u0)
	minHSV = min_HSV(Wc, Wo)
end

function plotting()
    lambda = range(0, 1, 20)
    HSVs = []
    for i = 1:length(lambda)
        HSVs = push!(HSVs, compute_minHSV(collect(lambda)[i]))
    end
    plot(lambda,
        HSVs,
        xlabel = "Actuator effectiveness",
        ylabel = "Minimum HSVs",
        label = nothing,
    )
end
nothing
