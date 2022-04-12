using FTCTests
const FTC = FaultTolerantControl
using LinearAlgebra
using Plots
using UnPack
using Debugger
using ReferenceFrameRotations


"""
# Refs
[1] M. Tahavori and A. Hasan, “Fault recoverability for nonlinear systems with application to fault tolerant control of UAVs,” Aerosp. Sci. Technol., vol. 107, p. 106282, 2020, doi: 10.1016/j.ast.2020.106282.

# Notes
- x = state vector, [eta, omega, v, xi]^T
    - eta = Euler angle vector, [phi, theta, psi]^T
    - omega = angular rate vector, [p, q, r]^T
    - v = velocity vector, [u, v, w]^T
    - xi = position vector, [x, y, z]^T
- u = control input vector, thrust vector, [omega_1, omega_2, omega_3, omega_4]^T
- y = output vector, [eta, omega, xi]^T
"""
function compute_minHSV_example(lambda, num::Int; dt=0.01, tf=1.0)
    @assert lambda >= 0.0 && lambda <= 1.0
    Λ = diagm(ones(4))
    Λ[num, num] = lambda
    # @show Λ
    # Quadcopter state space model [1]
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

    T(x) = [1 sin(x[1])*tan(x[2]) cos(x[1])*tan(x[2]);
            0 cos(x[1]) -sin(x[1]);
            0 sec(x[2])*sin(x[1]) cos(x[1])*sec(x[2])]
    R(x) = [cos(x[2])*cos(x[3]) sin(x[1])*sin(x[2])*cos(x[3])-cos(x[1])*sin(x[3]) cos(x[1])*sin(x[2])*cos(x[3])+sin(x[1])*sin(x[3]);
            cos(x[2])*sin(x[3]) sin(x[1])*sin(x[2])*sin(x[3])-cos(x[1])*cos(x[3]) cos(x[1])*sin(x[2])*sin(x[3])-sin(x[1])*cos(x[3]);
            -sin(x[2]) sin(x[1])*cos(x[2]) cos(x[1])*cos(x[2])]
    F(x) = vec([
        T(x) * x[4:6]
        Jinv * cross(-x[4:6], J * x[4:6])
        -cross(x[4:6], x[7:9]) + gc * R(x)' * [0; 0; 1]
        R(x) * x[7:9]
    ])

    f(x, u, p, t) = A*x + F(x) + B*(Λ*u).^2
    g(x, u, p, t) = C*x

	# System dimension
	n, m = size(B)
	l = size(C)[1]

    # Initial settings
    x0 = zeros(n)
    u0 = zeros(m)
    pr = zeros(4, 1)

    Wc = FTC.empirical_gramian(f, g, m, n, l; opt=:c, dt=dt, tf=tf, pr=pr, xs=x0, us=u0)
    Wo = FTC.empirical_gramian(f, g, m, n, l; opt=:o, dt=dt, tf=tf, pr=pr, xs=x0, us=u0)
    # minHSV = FTC.min_HSV(Wc, Wo)
    eigvals_Wc = Wc |> LinearAlgebra.eigvals |> minimum |> sqrt
end

# function Dynamics!(multicopter::IslamQuadcopter)
#     @unpack B = multicopter
#     function dynamics!(dx, x, param, t; u, Λ)
#         ν = B * Λ * u
#         f, M = ν[1], ν[2:4]
#         @nested_log FSimZoo.__Dynamics!(multicopter)(dx, x, (), t; f=f, M=M)
#     end
# end

# function test_model()
#     multicopter = IslamQuadcopter()
#     X = State(multicopter)()
#     Λ = diagm(ones(4))
#     u = (multicopter.m * multicopter.g / multicopter.kf) / 4 * ones(4)
#     dX = State(multicopter)()
#     Dynamics!(multicopter)(dX, X, (), 0.0; u=u, Λ=Λ)
#     dX
# end

# function compute_minHSV_Islam(lambda, num::Int; dt=0.01, tf=1.0)
#     @assert lambda >= 0.0 && lambda <= 1.0
#     Λ = diagm(ones(4))
#     Λ[num, num] = lambda
#     @show Λ
#     multicopter = IslamQuadcopter()
#     function f(x, u, param, t)
#         p = x[1:3]
#         v = x[4:6]
#         quat = x[7:10]
#         ω = x[11:13]
#         R = quat_to_dcm(Quaternion(quat...))
#         X = State(multicopter)(p, v, R, ω)
#         dX = State(multicopter)()  # initialisation
#         Dynamics!(multicopter)(dX, X, param, t; u=u, Λ=Λ)
#         dX_quat = dcm_to_quat(DCM(dX.R))
#         dx = [dX.p..., dX.v..., dX_quat.q0, dX_quat.q1, dX_quat.q2, dX_quat.q3, dX.ω...]
#         return dx
#     end
#     g(x, u, p, t) = x[7:10]  # different from [1]
#     n, m, l = 13, 4, 4
#     X0 = State(multicopter)()
#     quat = dcm_to_quat(DCM(X0.R))
#     _quat = [quat.q0, quat.q1, quat.q2, quat.q3]
#     x0 = [X0.p..., X0.v..., _quat..., X0.ω...]
#     # u0 = (multicopter.m * multicopter.g / multicopter.kf) / 4 * ones(4)
#     u0 = zeros(4)
#     pr = zeros(4, 1)

#     Wc = FTC.empirical_gramian(f, g, m, n, l; opt=:c, dt=dt, tf=tf, pr=pr, xs=x0, us=u0, xm=1.0, um=10000.0)
#     Wo = FTC.empirical_gramian(f, g, m, n, l; opt=:o, dt=dt, tf=tf, pr=pr, xs=x0, us=u0, xm=1.0, um=10000.0)
#     _eigvals_Wc = Wc |> LinearAlgebra.eigvals
#     eigvals_Wc = []
#     for eigval in _eigvals_Wc
#         if abs(imag(eigval)) < 1e-6
#             push!(eigvals_Wc, real(eigval))
#         else
#             error("Too large imaginary part")
#         end
#     end
#     min_HSV = eigvals_Wc |> minimum |> sqrt # not min_HSV
#     # minHSV = FTC.min_HSV(Wc, Wo)
# end

function plotting(rotor_idx)
    lambda = 0:0.10:1 |> collect
    HSVs = []
    for i = 1:length(lambda)
        HSVs = push!(HSVs, compute_minHSV_example(lambda[i], rotor_idx))
        # HSVs = push!(HSVs, compute_minHSV_Islam(lambda[i], rotor_idx))
    end
    return plot(lambda,
                HSVs,
                xlabel = "Actuator effectiveness",
                ylabel = "Minimum HSV",
                label = nothing,
               )
end

function main()
    figs = []
    for rotor_idx in 1:4
        fig = plotting(rotor_idx)
        figs = push!(figs, fig)
    end
    plot(figs..., layout=(2, 2))
end
