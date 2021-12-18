"""
t1: calculate maximum error from `t1` to `tf`
"""
function export_errors(file_path, t1::Real)
    loaded_data = JLD2.load(file_path)
    @unpack df, method, t0, tf = loaded_data
    @assert t1 < tf && t1 > t0
    filtered_df = filter(:time => t -> t >= t1, df)
    poss = filtered_df.sol |> Map(datum -> datum.plant.state.p) |> collect
    # poss_des = ...
    # errors_pos = poss - poss_des |> Map(norm) |> collect  # you may need to `using LinearAlgebra`
    error("WIP")  # error message for not completed works
    error_max = maximum(errors)
end

# function evaluate(errors, threshold)
#     @assert threshold > 0
#     mean(abs.((errors) .<= threshold))
# end
