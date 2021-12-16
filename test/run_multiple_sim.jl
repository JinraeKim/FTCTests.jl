using FTCTests  # reexport FaulTolerantControl
using Transducers
using Random


"""
euler = [ψ, θ, ϕ]  # yaw, pitch, roll
"""
function distribution_info(manoeuvre::Symbol)
    p_min, p_max = [-1, -1, -11.0], [1, 1, -9.0]
    v_min, v_max = nothing, nothing
    euler_min, euler_max = nothing, nothing
    ω_min, ω_max = nothing, nothing
    if manoeuvre == :hovering
        v_min, v_max = [-1, -1, -1.0], [1, 1, 1.0]
        euler_min, euler_max = [deg2rad(-5), deg2rad(-5), deg2rad(-5)], [deg2rad(5), deg2rad(5), deg2rad(5)]
        ω_min, ω_max = [deg2rad(-5), deg2rad(-5), deg2rad(-5)], [deg2rad(5), deg2rad(5), deg2rad(5)]
    elseif manoeuvre == :forward
        v_min, v_max = [3, -1, -1.0], [7, 1, 1.0]
        euler_min, euler_max = [deg2rad(-2), deg2rad(-10), deg2rad(-2)], [deg2rad(2), deg2rad(-5), deg2rad(2)]
        ω_min, ω_max = [deg2rad(-2), deg2rad(-2), deg2rad(-2)], [deg2rad(2), deg2rad(2), deg2rad(2)]
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
collector = collect (sequential computing)
collector = Transducers.tcollect (parallel computing)
"""
function run_multiple_sim(N=1; collector=Transducers.tcollect, will_plot=false, seed=2021)
    if collector == tcollect
        println("Parallel computing...")
        will_plot == true ? error("plotting figures not supported in tcollect") : nothing
    elseif collector == collect
        println("Sequential computing...")
    else
        error("Invalid collector")
    end
    Random.seed!(seed)
    dir_log = "data"
    # methods = [:adaptive, :optim, :adaptive2optim]
    method = :adaptive
    manoeuvre = :forward
    multicopter = LeeHexacopter()  # dummy
    faults = FaultSet(
                      LoE(3.0, 1, 0.0),
                      LoE(3.0, 3, 0.0),  # t, index, level
                     )  # Note: antisymmetric configuration of faults can cause undesirable control allocation; sometimes it is worse than multiple faults of rotors in symmetric configuration.
    τ = 0.0
    fdi = DelayFDI(τ)
    θs = [[0, 0, -10.0]]  # constant position tracking
    # θs = [[0, 0, 0], [3, 4, 5], [2, 1, -3]]  # Bezier curve
    tf = 20.0
    # run sim and save fig
    min_nt, max_nt = distribution_info(manoeuvre)
    x0s = 1:N |> Map(i -> FTCTests.sample(multicopter, min_nt, max_nt)) |> collect
    @time saved_data_array = zip(1:N, x0s) |> MapSplat((i, x0) ->
                                                       FTCTests.run_sim(method, x0, multicopter, faults, fdi, θs, tf,
                                                               joinpath(dir_log, lpad(string(i), 4, '0')); will_plot=will_plot)) |> collector
    nothing
end
