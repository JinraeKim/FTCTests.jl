using FTCTests
using Test

@testset "FTCTests.jl" begin
    include("privileged_name.jl")
    include("run_sim.jl")
    include("evaluate.jl")
end
