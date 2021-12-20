using FTCTests


"""
# Notes
- (`manoeuvre`) :hovering, :forward, etc.
- (`method`) :adaptive, :adaptive2optim, etc.
"""
function main(manoeuvre::Symbol=:hovering, method::Symbol=:adaptive; _dir_log="data")
    println("(manoeuvre: $(manoeuvre), method: $(method))")
    time_criterion = 15.0
    threshold = 1.0
    results = []
    dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
    for case_number in 1:length(readdir(dir_log))
        file_path = joinpath(dir_log, lpad(string(case_number), 4, '0') * "_" * FTCTests.TRAJ_DATA_NAME)
        result, error_max = FTCTests.evaluate(file_path, time_criterion, threshold)
        push!(results, result)
    end
    if results[1] == true
        println("Success.")
    else
        println("Fail.")
    end
end
