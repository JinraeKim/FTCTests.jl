"""
    evaluate

Evaluate whether the mission is success or failure.

# Notes
jld2: a loaded dictionary from `JLD2.load`.
"""
function evaluate(jld2::Dict, t1::Real, threshold::Real)
    @assert threshold > 0
    @unpack df, traj_des, t0, tf = jld2
    @assert t0 < t1 && t1 < tf
    df_filtered = filter(:time => t -> t >= t1, df)
    poss = df_filtered.sol |> Map(datum -> datum.plant.state.p) |> collect
    poss_des = df_filtered.time |> Map(traj_des) |> collect
    error_max = poss - poss_des |> Map(norm) |> collect |> maximum
    is_success = error_max <= threshold
end
