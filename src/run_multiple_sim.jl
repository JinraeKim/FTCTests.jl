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
- `manoeuvres` is an array of manoeuvres.
"""
function run_multiple_sim(
        N::Int,
        manoeuvres::AbstractArray{Symbol},
        methods::AbstractArray{Symbol},
        _faults,
        θs_array,  # path parameter
        t0::Real,
        tf::Real,
        h_threshold::Union{Real, Nothing},  # m (nothing: no constraint)
        actual_time_limit::Union{Real, Nothing},  # s
        N_thread::Int,
        collector,
        will_plot::Bool,
        seed::Int,
    )
    println("# of simulation cases: $(N)")
    println("manoeuvres: $(manoeuvres)")
    println("methods: $(methods)")
    if collector == tcollect
        println("Parallel computing...")
        will_plot == true ? error("plotting figures not supported in tcollect") : nothing
    elseif collector == collect
        println("Sequential computing...")
    else
        error("Invalid collector")
    end
    Random.seed!(seed)
    _dir_log = joinpath("data", "N_$(N)_seed_$(seed)")
    multicopter = LeeHexacopter()  # dummy
    trajs_des = θs_array |> Map(θs -> Bezier(θs, t0, tf)) |> collect
    # run sim and save fig
    for manoeuvre in manoeuvres
        x0s = 1:N |> Map(i -> FTCTests.sample(multicopter, distribution_info(manoeuvre)...)) |> collect
        for method in methods
            dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
            if method == :adaptive  # method `:adaptive` does not require FDI information; not affected by FDI delay time constant `τ`.
                τs = [0.0]
            elseif method == :adaptive2optim
                τs = [0.0, 0.1]
            else
                error("Invalid method")
            end
            for τ in τs
                case_numbers_partition = 1:N |> Partition(N_thread; flush=true) |> Map(copy) |> collect
                for case_numbers in case_numbers_partition
                    @time _ = zip(case_numbers,
                                x0s[case_numbers],
                                _faults[case_numbers],
                                trajs_des[case_numbers],
                               ) |>
                    MapSplat((i, x0, _fault, traj_des) -> FTCTests.run_sim(method, x0, multicopter,
                                                                           FaultSet(_fault...),
                                                                           DelayFDI(τ),
                                                                           traj_des, dir_log, i;
                                                                           will_plot=will_plot,
                                                                           t0=t0, tf=tf,
                                                                           h_threshold=h_threshold,
                                                                           actual_time_limit=actual_time_limit,
                                                                          )) |> collector
                end
            end
        end
    end
    nothing
end

