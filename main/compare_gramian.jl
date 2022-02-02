using FTCTests
using ControlSystems: ss, gram
using LinearAlgebra


function compute_empirical_gramian()
	A = -Matrix(I, 4, 4)
	B = [0.0 1.0 0.0 1.0]'
	C = [0.0 0.0 1.0 1.0]

	f(x, u, p, t) = A*x + B*u .+ p
	g(x, u, p, t) = C*x

	# System dimension
	n = 4
	m = 1
	l = 1

	x0 = [0.0, 0.0, 0.0, 0.0]
	u0 = [0.0]

	Wc = empirical_ctrl_gramian(f, [m, n, l]; dt=0.01, tf=1.0, pr=zeros(4, 1), xs=x0)
	Wo = empirical_obsv_gramian(f, g, [m, n, l]; dt=0.01, tf=1.0, pr=zeros(4, 1), xs=x0, us=u0)
	@show Wc Wo
    nothing
end

function compute_gramian()
	A = -Matrix(I, 4, 4)
	B = [0.0 1.0 0.0 1.0]'
	C = [0.0 0.0 1.0 1.0]
    D = [0]

    sys = ss(A, B, C, D)

    Wc = gram(sys, :c)
    Wo = gram(sys, :o)
    @show Wc Wo
    nothing
end
