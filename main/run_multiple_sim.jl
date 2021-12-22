using FTCTests  # reexport FaulTolerantControl
using Transducers
using Random
using Test


"""
euler = [ψ, θ, ϕ]  # yaw, pitch, roll
"""
function distribution_info(manoeuvre::Symbol)
    p_min, p_max = nothing, nothing
    v_min, v_max = nothing, nothing
    euler_min, euler_max = nothing, nothing
    ω_min, ω_max = nothing, nothing
    if manoeuvre == :hovering
        p_min, p_max = [-1, -1, -11.0], [1, 1, -9.0]
        v_min, v_max = [-1, -1, -1.0], [1, 1, 1.0]
        euler_min, euler_max = [deg2rad(-5), deg2rad(-5), deg2rad(-5)], [deg2rad(5), deg2rad(5), deg2rad(5)]
        ω_min, ω_max = [deg2rad(-5), deg2rad(-5), deg2rad(-5)], [deg2rad(5), deg2rad(5), deg2rad(5)]
    elseif manoeuvre == :forward
        p_min, p_max = [-1, -1, -11.0], [1, 1, -9.0]
        v_min, v_max = [3, -1, -1.0], [7, 1, 1.0]
        euler_min, euler_max = [deg2rad(-2), deg2rad(-10), deg2rad(-2)], [deg2rad(2), deg2rad(-5), deg2rad(2)]
        ω_min, ω_max = [deg2rad(-2), deg2rad(-2), deg2rad(-2)], [deg2rad(2), deg2rad(2), deg2rad(2)]
    elseif manoeuvre == :debug
        p_min, p_max = [0, 0, -10.0], [0, 0, -10.0]
        v_min, v_max = zeros(3), zeros(3)
        euler_min, euler_max = zeros(3), zeros(3)
        ω_min, ω_max = zeros(3), zeros(3)
    else
        error("Invalid manoeuvre")
    end
    min_nt = (;
              p=p_min,
              v=v_min,
              euler=euler_min,
              ω=ω_min,
             )
    max_nt = (;
              p=p_max,
              v=v_max,
              euler=euler_max,
              ω=ω_max,
             )
    min_nt, max_nt
end


"""
    run_multiple_sim()

A function for running multiple simulation.
This is used for 2nd-year report.

# Notes
- collector = collect (sequential computing)
- collector = Transducers.tcollect (parallel computing)
- manoeuvre = :hovering or :forward (:debug for debugging)
"""
function run_multiple_sim(manoeuvre::Symbol, N=1;
        N_thread=Threads.nthreads(),
        collector=Transducers.tcollect, will_plot=false, seed=2021)
    println("Simulation case: $(N)")
    if collector == tcollect
        println("Parallel computing...")
        will_plot == true ? error("plotting figures not supported in tcollect") : nothing
    elseif collector == collect
        println("Sequential computing...")
    else
        error("Invalid collector")
    end
    Random.seed!(seed)
    _dir_log = "data"
    # methods = [:adaptive, :optim, :adaptive2optim]
    multicopter = LeeHexacopter()  # dummy
    fault_time = 0.0
    _fault_list_single = [[
                          [LoE(fault_time, index, effectiveness)]
                          for index in 1:6
                          for effectiveness in [0.9, 0.5, 0.1, 0.0]
                         ]...]
    _fault_list_double = [[
                          [LoE(fault_time, index, effectiveness),
                           LoE(fault_time, index2, effectiveness)]
                          for index in 1:5
                          for index2 in index+1:6
                          for effectiveness in [0.9, 0.5, 0.1, 0.0]
                         ]...]
    _fault_list_single_failure_single_fault = [[
                                               [LoE(fault_time, index, 0.0),
                                                LoE(fault_time, index2, effectiveness)]
                                               for index in 1:6
                                               for index2 in filter(x -> x != index, 1:6)
                                               for effectiveness in [0.9, 0.5, 0.1]
                                              ]...]
    _fault_list = [_fault_list_single..., _fault_list_double..., _fault_list_single_failure_single_fault...]
    _faults = 1:N |> Map(i -> rand(_fault_list)) |> collect  # randomly sampled N faults
    τs = 1:N |> Map(i -> rand([0.0, 0.1])) |> collect  # FDI delay (0.0 or 0.1s)
    θs = [[0, 0, -10.0]]  # constant position tracking
    # θs = [[0, 0, 0], [3, 4, 5], [2, 1, -3]]  # Bezier curve
    t0, tf = 0.0, 20.0
    traj_des = Bezier(θs, t0, tf)
    # run sim and save fig
    x0s = 1:N |> Map(i -> FTCTests.sample(multicopter, distribution_info(manoeuvre)...)) |> collect
    for method in [:adaptive, :adaptive2optim]
        dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
        x0s = 1:N |>
        Map(i -> FTCTests.sample(multicopter, distribution_info(manoeuvre)...)) |>
        collect
        case_numbers_partition = 1:N |> Partition(N_thread; flush=true) |> Map(copy) |> collect
        for case_numbers in case_numbers_partition
            @time _ = zip(case_numbers,
                          x0s[case_numbers],
                          _faults[case_numbers],
                          τs[case_numbers]) |>
            MapSplat((i, x0, _fault, τ) -> FTCTests.run_sim(method, x0, multicopter,
                                                            FaultSet(_fault...),
                                                            DelayFDI(τ),
                                                            traj_des, dir_log, i;
                                                            will_plot=will_plot,
                                                            t0=t0, tf=tf)) |> collector
        end
    end
    nothing
end
