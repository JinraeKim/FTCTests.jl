using FTCTests


function main(dir_log="data/adaptive/hovering/0001")
    time_criterion = 15.0
    threshold = 1.0

    file_path = joinpath(dir_log, FTCTests.TRAJ_DATA_NAME)
    # errors = [-1; 2; 0]  # for test
    errors = FTCTests.export_errors(file_path, time_criterion)
    recovery_rate = 100 * FTCTests.evaluate(errors, threshold)
end
