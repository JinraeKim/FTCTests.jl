"""
    export_error_max(file_path, t1::Real)
Export maximum position error of single trajectory data (loaded from `file_path`) in time period: `t1 < t < tf`.
"""
function export_error_max(file_path, t1::Real)
    data_loaded = JLD2.load(file_path)
    @unpack df, method, t0, tf, traj_des = data_loaded
    @assert t1 < tf && t1 > t0
    df_filtered = filter(:time => t -> t >= t1, df)
    poss = df_filtered.sol |> Map(datum -> datum.plant.state.p) |> collect
    poss_des = df_filtered.time |> Map(traj_des) |> collect
    errors_pos_norm = poss - poss_des |> Map(norm) |> collect
    error_max = maximum(errors_pos_norm)
end

"""
    evaluate(errors, threshold::Real)
Evaluate whether each error does not exceed given `threshold`.
"""
function evaluate(errors, threshold::Real)
    @assert threshold > 0
    mean(abs.((errors) .<= threshold))
end
