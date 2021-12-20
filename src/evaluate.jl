"""
    evaluate(file_path, t1::Real, threshold::Real)
Evaluate whether the maximum error of trajectory data (loaded from `file_path`) does not exceed given `threshold` (check time period: `t1 < t < tf`) and export the maximum position error.
"""
function evaluate(file_path, t1::Real, threshold::Real)
    @assert threshold > 0
    data_loaded = JLD2.load(file_path)
    @unpack df, method, faults, fdi, t0, tf, traj_des = data_loaded
    @assert t1 < tf && t1 > t0
    df_filtered = filter(:time => t -> t >= t1, df)
    poss = df_filtered.sol |> Map(datum -> datum.plant.state.p) |> collect
    poss_des = df_filtered.time |> Map(traj_des) |> collect
    errors_pos_norm = poss - poss_des |> Map(norm) |> collect
    error_max = maximum(errors_pos_norm)
    result = error_max <= threshold
    return result, error_max, faults, fdi
end

function calculate_recovery_rate(results)
    mean(results)
end
