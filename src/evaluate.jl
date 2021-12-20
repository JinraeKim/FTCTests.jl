"""
    evaluate

Evaluate whether the maximum error of trajectory data does not exceed given `threshold` (check time period: `t1 < t < tf`) and export the maximum position error.
"""
function evaluate(error_poss::Vector{Vector{T}} where T <: Number, t1::Real, threshold::Real)
    @assert threshold > 0
    error_poss_norm = error_poss |> Map(norm) |> collect
    error_max = maximum(error_poss_norm)
    is_success = error_max <= threshold
end
