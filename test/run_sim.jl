using Test
using FileIO


@testset "run_sim" begin
    dir_log = "__data__"
    file_path = joinpath(dir_log, "tmp.jld2")
    case_number = 1
    mkpath(dir_log)
    method = :adaptive
    args_multicopter = ()  # default
    multicopter = LeeHexacopter()
    fault = FaultSet(
                     LoE(3.0, 1, 0.9),
                    )
    fdi = DelayFDI(0.1)  # 0.1 sec delay
    t0, tf = 0.0, 0.1
    θs = [[0, 0, 0.0]]  # constant position tracking
    traj_des = Bezier(θs, t0, tf)
    sim_res = run_sim(method, args_multicopter, multicopter, fault, fdi, traj_des, dir_log, case_number;
                      t0=t0, tf=tf, savestep=0.01)
    FileIO.save(file_path, sim_res)
    plot_figures(multicopter, dir_log, sim_res)
end
