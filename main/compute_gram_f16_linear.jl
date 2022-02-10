using FTCTests
const FTC = FaultTolerantControl
using LinearAlgebra
using Plots


"""
# Refs
[1] K. G. Vamvoudakis and F. L. Lewis, “Online actor-critic algorithm to solve the continuous-time infinite horizon optimal control problem,” Automatica, vol. 46, no. 5, pp. 878–888, 2010, doi: 10.1016/j.automatica.2010.02.018.

# Notes
- x = state vector, [v, alpha, q]^T
- u = control input vector, [dele]
"""
function compute_minHSV(eff)
    # F16 aircraft longitudinal linear system model [1]
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
