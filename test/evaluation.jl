using FTCTests


"""
# Notes
- (`manoeuvre`) :hovering, :forward, etc.
- (`method`) :adaptive, :adaptive2optim, etc.
"""
function main(manoeuvre::Symbol=:hovering, method::Symbol=:adaptive; _dir_log="data")
    println("(manoeuvre: $(manoeuvre), method: $(method)")
    _dir_log = "data"
    time_criterion = 15.0
    threshold = 1.0
    errors = []
    dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
    while true
        file_path = joinpath(dir_log, lpad(string(case_number), 4, '0') * "_" * FTCTests.TRAJ_DATA_NAME)
        if isfile(file_path)
            single_error = FTCTests.export_error_max(file_path, time_criterion)
            push!(errors, single_error)
            case_number += 1
        else
            break
        end
    end
    # @show errors, case_number
    recovery_rate = 100 * FTCTests.evaluate(errors, threshold)
    println("Recovery rate is: $(recovery_rate) percent.")
end
