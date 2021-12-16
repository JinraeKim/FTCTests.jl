# using FaultTolerantControl
# const FTC = FaultTolerantControl
# using UnPack
# using Transducers
using DataFrames
using JLD2, FileIO
using Statistics
using DifferentialEquations
# using LinearAlgebra
# using NumericalIntegration
# using ReferenceFrameRotations


function export_errors(dir_log)
    file_path = joinpath(dir_log, "traj.jld2")
    loaded_data = JLD2.load(file_path)
    # df = loaded_data
    # ts = df.time
    # poss = df.sol |> Map(datum -> datum.plant.state.p) |> collect
    # zs = poss |> Map(pos -> pos[3]) |> collect
    # poss_desired = ts |> Map(pos_cmd_func) |> collect
    # zs_des = poss_desired |> Map(pos -> pos[3]) |> collect
    # z_error = zs - zs_des
    # z_error_max = max(z_error)
end

function evaluate(errors, threshold)
    @assert threshold > 0
    mean(abs.((errors) .<= threshold))
end

function main(dir_log="test/data/adaptive/0001")
    # errors = [-1; 2; 0]  # for test
    errors = export_errors(dir_log)
    # threshold = 1.0
    # recovery_rate = 100 * evaluate(errors, threshold)
end
