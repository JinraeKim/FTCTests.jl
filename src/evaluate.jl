"""
    evaluate

Evaluate whether the maximum error of trajectory data does not exceed given `threshold` (check time period: `t1 < t < tf`) and export the maximum position error.
"""
function evaluate(error_poss::Vector{Vector{T}} where T <: Number,
        t1::Real, threshold::Real)
    @assert threshold > 0
    # @unpack df, method, faults, fdi, t0, tf, traj_des = data_loaded
    # @assert t1 < tf && t1 > t0
    # df_filtered = filter(:time => t -> t >= t1, df)
    # poss = df_filtered.sol |> Map(datum -> datum.plant.state.p) |> collect
    # poss_des = df_filtered.time |> Map(traj_des) |> collect
    # errors_pos_norm = poss - poss_des |> Map(norm) |> collect
    errors_pos_norm = error_poss |> Map(norm) |> collect
    error_max = maximum(errors_pos_norm)
    is_success = error_max <= threshold
    @show is_success
    @show error_max
    @show threshold
    (; is_success=is_success, error_max=error_max)
end
