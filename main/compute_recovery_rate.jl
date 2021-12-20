using FTCTests
using JLD2
using UnPack


function compute_recovery_rate()
    case_number = 1
    manoeuvre, method = :hovering, :adaptive
    _dir_log = "data"
    t1 = 15.0
    threshold = 1.0
    dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
    file_path = joinpath(dir_log, lpad(string(case_number), 4, '0') * "_" * FTCTests.TRAJ_DATA_NAME)
    jld2 = JLD2.load(file_path)
    is_success = evaluate(jld2, t1, threshold)
end
