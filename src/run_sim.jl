function sample(multicopter::Multicopter, min_nt, max_nt)
    p = min_nt.p + (max_nt.p - min_nt.p) .* rand(3)
    v = min_nt.v + (max_nt.v - min_nt.v) .* rand(3)
    euler = min_nt.euler + (max_nt.euler - min_nt.euler) .* rand(3)
    ω = min_nt.ω + (max_nt.ω - min_nt.ω) .* rand(3)
    R = angle_to_dcm(euler..., :ZYX)
    (p, v, R, ω,)  # tuple; args_multicopter
end

function run_sim(method, args_multicopter, multicopter::FlightSims.Multicopter,
        faults::Array{FTC.AbstractFault}, fdi::FTC.DelayFDI, traj_des::FTC.AbstractTrajectory,
        dir_log::String, case_number::Int;
        t0=0.0, tf=20.0,
        savestep=0.01,
        dir_figure=nothing,
        h_threshold=nothing,
        actual_time_limit=nothing,
    )
    pos_cmd_func(t) = traj_des(t)
    mkpath(dir_log)
    file_path = joinpath(dir_log, lpad(string(case_number), 4, '0') * "_τ_" * replace(string(fdi.τ), "." => "_") * "_" * TRAJ_DATA_NAME)
    @show file_path
    @unpack m, B, u_min, u_max, dim_input = multicopter
    plant = FTC.DelayFDI_Plant(multicopter, fdi, faults)
    @unpack multicopter = plant
    controller = BacksteppingPositionController(m; pos_cmd_func=pos_cmd_func)
    # optimisation-based allocators
    # allocator = PseudoInverseAllocator(B)  # deprecated; it does not work when failures occur. I guess it's due to Moore-Penrose pseudo inverse.
    allocator = ConstrainedAllocator(B, u_min, u_max)
    control_system_optim = FTC.BacksteppingControl_StaticAllocator_ControlSystem(controller, allocator)
    env_optim = FTC.DelayFDI_Plant_BacksteppingControl_StaticAllocator_ControlSystem(plant, control_system_optim)
    # adaptive allocators
    allocator = AdaptiveAllocator(B)
    control_system_adaptive = FTC.BacksteppingControl_AdaptiveAllocator_ControlSystem(controller, allocator)
    env_adaptive = FTC.DelayFDI_Plant_BacksteppingControl_AdaptiveAllocator_ControlSystem(plant, control_system_adaptive)
    p0, x0 = nothing, nothing
    if method == :adaptive || method == :adaptive2optim
        p0 = :adaptive
        x0 = State(env_adaptive)(; args_multicopter=args_multicopter)  # start with adaptive CA
    elseif method == :optim
        p0 = :optim
        x0 = State(env_optim)(; args_multicopter=args_multicopter)  # start with optim CA
    else
        error("Invalid method")
    end
    @Loggable function dynamics!(dx, x, p, t)
        @log method = p
        if p == :adaptive
            @nested_log Dynamics!(env_adaptive)(dx, x, p, t)
        elseif p == :optim
            @nested_log Dynamics!(env_optim)(dx, x, p, t)
        else
            error("Invalid method")
        end
    end
    # callback; TODO: a fancy way of utilising callbacks like SimulationLogger.jl...?
    __log_indicator__ = __LOG_INDICATOR__()
    affect! = (integrator) -> error("Invalid method")
    if method == :adaptive2optim
        affect! = (integrator) -> integrator.p = :optim
    elseif method == :adaptive || method == :optim
        affect! = (integrator) -> nothing
    end
    condition = function (x, t, integrator)
        p = integrator.p
        if p == :adaptive
            x = copy(x)
            dict = Dynamics!(env_adaptive)(zero.(x), x, p, t, __log_indicator__)
            u_actual = dict[:plant][:input][:u_actual]
            is_switched = any(u_actual .>= u_max) || any(u_actual .<= u_min)
            return is_switched
        elseif p == :optim
            return false
        else
            error("Invalid method")
        end
    end
    cb_switch = DiscreteCallback(condition, affect!)
    cbs = Any[cb_switch]
    simulation_height_success = true
    # termination
    if h_threshold != nothing
        function terminate_condition(X, t, integrator)
            @unpack p = X.plant.multicopter
            h = -p[3]  # h = -z
            h < h_threshold
        end
        function terminate_affect!(integrator)
            simulation_height_success = false
            @warn("Simulation is terminated due to the loss of height")
            terminate!(integrator)
        end
        cb_terminate = DiscreteCallback(terminate_condition, terminate_affect!)
        push!(cbs, cb_terminate)
    end
    simulation_actual_time_success = true
    _t0 = time()
    if actual_time_limit != nothing
        @assert actual_time_limit > 0.0
        function terminate_condition_time(X, t, integrator)
            _t = time()
            (_t - _t0) > actual_time_limit
        end
        function terminate_affect_time!(integrator)
            simulation_actual_time_success = false
            @warn("Simulation is terminated 'cause it exceeds the actual time limit of $(actual_time_limit) [s]")
            terminate!(integrator)
        end
        cb_terminate_time = DiscreteCallback(terminate_condition_time, terminate_affect_time!)
        push!(cbs, cb_terminate_time)
    end
    cb = CallbackSet(cbs...)
    # sim
    simulator = Simulator(
                          x0, dynamics!, p0;
                          t0=t0, tf=tf,
                         )
    # TODO: time exceed should be in `solve` for properly measuring elapsed time
    df = solve(simulator;
               savestep=savestep,
               callback=cb,
              )
    sim_res = Dict(
                   "df" => df,
                   "method" => String(method),
                   "faults" => faults,
                   "fdi" => fdi,
                   "t0" => t0,
                   "tf" => tf,
                   "traj_des" => traj_des,
                   "simulation_height_success" => simulation_height_success,
                   "simulation_actual_time_success" => simulation_actual_time_success,
                  )
    FileIO.save(file_path, sim_res)
    if dir_figure != nothing
        plot_figures(multicopter, dir_figure, sim_res)
    end
    sim_res
end


function plot_figures(multicopter, dir_figure, sim_res::Dict)
    mkpath(dir_figure)
    @unpack u_min, u_max, dim_input = multicopter
    @unpack df, method, traj_des = sim_res
    pos_cmd_func(t) = traj_des(t)
    # data
    ts = df.time
    poss = df.sol |> Map(datum -> datum.plant.state.p) |> collect
    xs = poss |> Map(pos -> pos[1]) |> collect
    ys = poss |> Map(pos -> pos[2]) |> collect
    zs = poss |> Map(pos -> pos[3]) |> collect
    poss_desired = ts |> Map(pos_cmd_func) |> collect
    xs_des = poss_desired |> Map(pos -> pos[1]) |> collect
    ys_des = poss_desired |> Map(pos -> pos[2]) |> collect
    zs_des = poss_desired |> Map(pos -> pos[3]) |> collect
    Rs = df.sol |> Map(datum -> datum.plant.state.R) |> collect
    eulers = Rs |> Map(R -> ReferenceFrameRotations.dcm_to_angle(SMatrix{3, 3}(R))) |> collect
    ψs = eulers |> Map(euler -> euler.a1) |> collect
    θs = eulers |> Map(euler -> euler.a2) |> collect
    ϕs = eulers |> Map(euler -> euler.a3) |> collect
    us_cmd = df.sol |> Map(datum -> datum.plant.input.u_cmd) |> collect
    us_actual = df.sol |> Map(datum -> datum.plant.input.u_actual) |> collect
    us_saturated = df.sol |> Map(datum -> datum.plant.input.u_saturated) |> collect
    us_cmd_faulted = df.sol |> Map(datum -> datum.plant.FDI.Λ * datum.plant.input.u_cmd) |> collect
    νs = df.sol |> Map(datum -> datum.plant.input.ν) |> collect
    Fs = νs |> Map(ν -> ν[1]) |> collect
    Ms = νs |> Map(ν -> ν[2:4]) |> collect
    νds = df.sol |> Map(datum -> datum.νd) |> collect
    Fds = νds |> Map(ν -> ν[1]) |> collect
    Mds = νds |> Map(ν -> ν[2:4]) |> collect
    Λs = df.sol |> Map(datum -> datum.plant.FDI.Λ) |> collect
    Λ̂s = df.sol |> Map(datum -> datum.plant.FDI.Λ̂) |> collect
    _Λs = Λs |> Map(diag) |> collect
    _Λ̂s = Λ̂s |> Map(diag) |> collect
    _method_dict = Dict(:adaptive => 0, :optim => 1)
    _methods = df.sol |> Map(datum -> _method = datum.method == :adaptive ? _method_dict[:adaptive] : _method_dict[:optim]) |> collect
    control_squares = us_actual |> Map(u -> norm(u, 2)^2) |> collect
    control_inf_norms = us_actual |> Map(u -> norm(u, Inf)) |> collect
    _∫control_squares = cumul_integrate(ts, control_squares)  # ∫ u' * u
    ∫control_squares = _∫control_squares .- _∫control_squares[1]  # to make the first element 0
    _∫control_inf_norms = cumul_integrate(ts, control_inf_norms)  # ∫ u' * u
    ∫control_inf_norms = _∫control_inf_norms .- _∫control_inf_norms[1]
    # @show ∫control_squares[end]
    # @show ∫control_inf_norms[end]
    # plots
    ts_tick = ts[1:100:end]
    tstr = ts_tick |> Map(t -> @sprintf("%0.0f", t)) |> collect
    tstr_empty = ts_tick |> Map(t -> "") |> collect
    ## pos
    p_pos = plot(;
                 title="position",
                 legend=:bottomright,
                 ylabel="position (m)"
                )
    xticks!(ts_tick, tstr_empty)
    plot!(p_pos, ts, xs;
          label="x",
          color=1,  # i'th default color
         )
    plot!(p_pos, ts, ys;
          label="y",
          color=2,  # i'th default color
         )
    plot!(p_pos, ts, zs;
          label="z",
          color=3,  # i'th default color
         )
    plot!(p_pos, ts, xs_des;
          label=nothing, ls=:dash,
          color=1,  # i'th default color
         )
    plot!(p_pos, ts, ys_des;
          label=nothing, ls=:dash,
          color=2,  # i'th default color
         )
    plot!(p_pos, ts, zs_des;
          label=nothing, ls=:dash,
          color=3,  # i'th default color
         )
    ## Λ
    p__Λ = plot(ts, hcat(_Λ̂s...)'; title="effectiveness vector",
                ylim=(-0.1, 1.1),
                label=["estimated" fill(nothing, dim_input-1)...],
                ylabel="diag(Λ)",
                color=:black,
         )
    xticks!(ts_tick, tstr_empty)
    plot!(p__Λ, ts, hcat(_Λs...)';
                label=["true" fill(nothing, dim_input-1)...],
                color=:red,
                ls=:dash,
                legend=:right,
               )
    # method
     p_method = plot(;
                     title="method (adaptive: $(_method_dict[:adaptive]), optim: $(_method_dict[:optim]))",
                     legend=:topleft,
                    )
     plot!(p_method, ts, hcat(_methods...)';
           label="",
           color=:black,
           ylabel="method",
           xlabel="t (s)",
           ylim=(-0.1, 1.1),
          )
     xticks!(ts_tick, tstr)
    ## states
     p_state = plot(p_pos, p__Λ, p_method;
                    link=:x,  # aligned x axes
                    layout=(3, 1), size=(600, 600),
                   )
     savefig(p_state, joinpath(dir_figure, "state.pdf"))
    p_state = plot(p_pos, p__Λ;
                   link=:x,  # aligned x axes
                   layout=(2, 1), size=(600, 600),
                  )
    savefig(p_state, joinpath(dir_figure, "state.pdf"))
    savefig(p_state, joinpath(dir_figure, "state.png"))
    ## u
    p_u = plot(;
               title="rotor input",
               legend=:topleft,
               ylabel="rotor force (N)",
              )
    xticks!(ts_tick, tstr_empty)
    plot!(p_u, ts, hcat(us_actual...)';
          # ylim=(-0.1*maximum(u_max), 1.1*maximum(u_max)),
          label=["input" fill(nothing, dim_input-1)...],
          color=:black,
          ylim=(minimum(u_min)-1, maximum(u_max)+11)
         )
    plot!(p_u, ts, maximum(u_max)*ones(size(ts));
          label="input min/max",
          ls=:dash,
          color=:red,
         )
    plot!(p_u, ts, minimum(u_min)*ones(size(ts));
          label=nothing,
          ls=:dash,
          color=:red,
         )
    # plot!(p_u, ts, hcat(us_cmd...)';
    #       label=["command" fill(nothing, dim_input-1)...],
    #       color=:red,
    #       ls=:dash,
    #      )
    # plot!(p_u, ts, hcat(us_saturated...)';
    #       # ylim=(-0.1*maximum(u_max), 1.1*maximum(u_max)),
    #       label=["saturated command" fill(nothing, dim_input-1)...],
    #       color="green",
    #      )
    # plot!(p_u, ts, hcat(us_cmd_faulted...)';
    #       label=["faulted command" fill(nothing, dim_input-1)...],
    #       color="orange",
    #       ls=:dash,
    #      )
    ## ν
    # legend_ν = method == :adaptive ? :topleft : :left
    legend_ν = :bottomleft
    # p_ν = plot(;
    #            title="virtual input",
    #            legend=legend_ν,
    #            ylabel="ν (N or N⋅m)",
    #           )
    # xticks!(ts_tick, tstr_empty)
    # plot!(p_ν, ts, hcat(νs...)';
    #       label=["actual input" fill(nothing, 4-1)...],
    #       color=:black,
    #      )
    # plot!(p_ν, ts, hcat(νds...)';
    #       label=["desired input" fill(nothing, 4-1)...],
    #       color=:red,
    #       ls=:dash,
    #      )
    # force
    p_F = plot(;
               title="force",
               ylabel="F (N)",
               ylim=(0, 60),
               legend=:bottomleft,
              )
    xticks!(ts_tick, tstr_empty)
    plot!(p_F, ts, hcat(Fs...)';
          label=["actual force" fill(nothing, 4-1)...],
          color=:black,
         )
    plot!(p_F, ts, hcat(Fds...)';
          label=["desired force" fill(nothing, 4-1)...],
          color=:red,
          ls=:dash,
         )
    # moment
    p_M = plot(;
               title="moment",
               ylabel="M (N⋅m)",
               xlabel="t (s)",
               ylim=(-100, 100),
               legend=:bottomleft,
              )
    xticks!(ts_tick, tstr)
    plot!(p_M, ts, hcat(Ms...)';
          label=["actual moment" fill(nothing, 4-1)...],
          color=:black,
         )
    plot!(p_M, ts, hcat(Mds...)';
          label=["desired moment" fill(nothing, 4-1)...],
          color=:red,
          ls=:dash,
         )
    # ## figure zoom
    # if method != :adaptive
    #     # fault 1
    #     t1_min, t1_max = 2, 4
    #     idx1 = findall(t -> t > t1_min && t < t1_max, ts)
    #     ts_idx1 = ts[idx1]
    #     Ms_idx1 = Ms[idx1]
    #     Mds_idx1 = Mds[idx1]
    #     @show size(ts_idx1)
    #     @show size(hcat(Mds_idx1...)')
    #     plot!(p_M, [ts_idx1 ts_idx1], [hcat(Ms_idx1...)' hcat(Mds_idx1...)'];
    #           inset = (1, bbox(0.1, 0.05, 0.3, 0.3)), subplot=2,
    #           ylim=(-5, 5), bg_inside=nothing, label=nothing,
    #           color=[:black :red], linestyle=[:solid :dash],
    #          )
    #     # fault 2
    #     t2_min, t2_max = 4, 6
    #     idx2 = findall(t -> t > t2_min && t < t2_max, ts)
    #     ts_idx2 = ts[idx2]
    #     Ms_idx2 = Ms[idx2]
    #     Mds_idx2 = Mds[idx2]
    #     @show size(ts_idx2)
    #     @show size(hcat(Mds_idx2...)')
    #     plot!(p_M, [ts_idx2 ts_idx2], [hcat(Ms_idx2...)' hcat(Mds_idx2...)'];
    #           inset = (1, bbox(0.5, 0.05, 0.3, 0.3)), subplot=3,
    #           ylim=(-5, 5), bg_inside=nothing, label=nothing,
    #           color=[:black :red], linestyle=[:solid :dash],
    #          )
    # end
    ### inputs
    # p_input = plot(p_u, p_ν, p_method;
    p_input = plot(p_u, p_F, p_M;
                   link=:x,  # aligned x axes
                   layout=(3, 1), size=(600, 600),
                  )
    savefig(p_input, joinpath(dir_figure, "input.pdf"))
    savefig(p_input, joinpath(dir_figure, "input.png"))
    # TODO: issue; adaptive control allocation seems not properly regulate ω_z error
    ## eulers
     p_euler = plot(;)
     plot!(p_euler, ts, rad2deg.(ϕs);
           color=1,
           label="ϕ (deg)",
          )
     plot!(p_euler, ts, rad2deg.(θs);
           color=2,
           label="θ (deg)",
          )
     plot!(p_euler, ts, rad2deg.(ψs);
           color=3,
           label="ψ (deg)",
          )
     savefig(p_euler, joinpath(dir_figure, "euler.pdf"))
     savefig(p_euler, joinpath(dir_figure, "euler.png"))
end
