using FTCTests
using Test
using Transducers
using LinearAlgebra
using DataFrames


@testset "evaluate" begin
    t0, tf = 0.0, 1.0
    ts = t0:0.01:tf
    d = 3
    sol = ts |> Map(t -> (; plant= (;state = (; p=ones(d))))) |> collect
    df = DataFrame(time=ts, sol=sol)
    traj_des(t) = zeros(d)
    jld2 = Dict("df" => df, "traj_des" => traj_des, "t0" => t0, "tf" => tf)
    t1 = 0.5
    error_norm = norm(ones(d))
    for threshold in [error_norm-0.1, error_norm+0.1]
        is_success = evaluate(jld2, t1, threshold)
        if error_norm < threshold
            @test is_success
        else
            @test !is_success
        end
    end
end
