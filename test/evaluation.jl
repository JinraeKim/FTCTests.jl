using FTCTests


function main(N)
    _dir_log = "data"
    method = :adaptive
    manoeuvre = :hovering
    dir_log = joinpath(joinpath(_dir_log, String(method)), String(manoeuvre))
    time_criterion = 15.0
    threshold = 1.0
    errors = []
    for i in 1:N
        __dir_log = joinpath(dir_log, lpad(string(i), 4, '0'))
        file_path = joinpath(__dir_log, FTCTests.TRAJ_DATA_NAME)
        single_error = FTCTests.export_error_max(file_path, time_criterion)
        push!(errors, single_error)
    end
    @show errors
    recovery_rate = 100 * FTCTests.evaluate(errors, threshold)
end
