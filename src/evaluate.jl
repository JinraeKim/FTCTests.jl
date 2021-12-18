"""
t1: calculate maximum error from `t1` to `tf`
"""
function export_errors(file_path, t1::Real)
    loaded_data = JLD2.load(file_path)
    @unpack df, method, t0, tf = loaded_data
    @assert t1 < tf && t1 > t0
    filtered_df = filter(:time => t -> t >= t1, df)
    poss = filtered_df.sol |> Map(datum -> datum.plant.state.p) |> collect
    xs = poss |> Map(pos -> pos[1]) |> collect
    ys = poss |> Map(pos -> pos[2]) |> collect
    zs = poss |> Map(pos -> pos[3]) |> collect

    errors = sqrt.(xs.^2 + ys.^2 + zs.^2)
    error_max = maximum(errors)
end

# function evaluate(errors, threshold)
#     @assert threshold > 0
#     mean(abs.((errors) .<= threshold))
# end
