using FTCTests
# using Statistics


function main(dir_log="data/0001")
    file_path = joinpath(dir_log, "traj.jld2")
    # errors = [-1; 2; 0]  # for test
    errors = FTCTests.export_errors(file_path)
    # threshold = 1.0
    # recovery_rate = 100 * evaluate(errors, threshold)
end
