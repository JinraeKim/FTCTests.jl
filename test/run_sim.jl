@testset "run_sim" begin
    dir_log = "__data__"
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
    run_sim(method, args_multicopter, multicopter, fault, fdi, traj_des, dir_log;
            t0=t0, tf=tf, savestep=0.01, will_plot=true,)
end
