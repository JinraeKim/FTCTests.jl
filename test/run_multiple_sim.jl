using FTCTests
using Test


@testset "run_multiple_sim" begin
    N = 1
    manoeuvres = [:debug]
    methods = [:adaptive]
    _faults = [
               [FaultTolerantControl.NoFault()],
              ]
    θs_array = [
                [zeros(3)],
               ]
    t0, tf = 0.0, 1.0
    h_threshold = nothing
    actual_time_limit = nothing
    N_thread = 1
    collector = collect
    will_plot = false
    seed = 2021
    run_multiple_sim(
                     N,
                     manoeuvres,
                     methods,
                     _faults,
                     θs_array,
                     t0,
                     tf,
                     h_threshold,
                     actual_time_limit,
                     N_thread,
                     collector,
                     will_plot,
                     seed,
                    )
end
