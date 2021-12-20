function main(manoeuvre::Symbol=:hovering, method::Symbol=:adaptive; _dir_log="data")
    println("(manoeuvre: $(manoeuvre), method: $(method))")
    threshold = 1.0
    dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
    case_number = 1
    file_path = joinpath(dir_log, lpad(string(case_number), 4, '0') * "_" * FTCTests.TRAJ_DATA_NAME)
    result, error_max = FTCTests.evaluate(file_path, time_criterion, threshold)

    if result == true
        println("Success.")
    else
        println("Fail.")
    end
end
