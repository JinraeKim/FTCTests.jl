using FTCTests
using JLD2
using Transducers
using UnPack


function compute_cost(file_path::String; cf=PositionAngularVelocityCostFunctional())
    jld2 = JLD2.load(file_path)
    @unpack df, traj_des = jld2
    ts = df.time
    poss = df.sol |> Map(datum -> datum.plant.state.p) |> collect
    poss_des = ts |> Map(traj_des) |> collect
    e_ps = poss .- poss_des
    @warn("TODO: there is no desired angular velocity")
    e_ωs = ts |> Map(t -> zeros(3)) |> collect
    (;
     ts=ts,
     e_ps=e_ps,
     e_ωs=e_ωs,
    )
    J = cost(cf, ts, e_ps, e_ωs)
end

function compute_costs(; dir_log="data/hovering/adaptive")
    @warn("TODO: change the directory location for your purpose")
    file_paths = readdir(dir_log; join=true)
    Js = file_paths |> Map(compute_cost) |> collect
end
