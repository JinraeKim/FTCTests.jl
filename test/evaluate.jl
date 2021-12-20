using FTCTests
using Test
using Transducers
using LinearAlgebra


@testset "evaluate" begin
    manoeuvre, method = :hovering, :adaptive
    t1 = 15.0
    N = 10  # length
    scale_factor = 1.0
    d = 3
    error_poss = 1:N |> Map(i -> scale_factor*(ones(d) / norm(ones(d)))) |> collect
    # poss_des = 1:N |> Map(i -> scale_factor*zeros(3)) |> collect
    for eps in [scale_factor-0.1, scale_factor+0.1]
        # res = FTCTests.evaluate(poss, poss_des, t1, eps)
        res = FTCTests.evaluate(error_poss, t1, eps)
        is_success = res.is_success
        if scale_factor < eps
            @test is_success
        else
            @test !is_success
        end
    end
end
