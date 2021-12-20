using FTCTests
using Test
using Transducers
using LinearAlgebra


@testset "evaluate" begin
    t1 = 15.0
    N = 10
    error_norm = 1.0
    d = 3
    error_poss = 1:N |> Map(i -> error_norm*(ones(d) / norm(ones(d)))) |> collect
    for threshold in [error_norm-0.1, error_norm+0.1]
        is_success = FTCTests.evaluate(error_poss, t1, threshold)
        if error_norm < threshold
            @test is_success
        else
            @test !is_success
        end
    end
end
