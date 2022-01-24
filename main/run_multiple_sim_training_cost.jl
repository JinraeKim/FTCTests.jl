using FTCTests  # reexport FaulTolerantControl
using Transducers
using Random
using Test


"""
This is for the training of cost function.
"""
function run_multiple_sim_training_cost(N=1;
        manoeuvres=[:hovering],
        methods=[:adaptive],
        t0=0.0, tf=20.0,
        h_threshold=nothing,  # m (nothing: no constraint)
        actual_time_limit=nothing,  # s (nothing: no constraint)
        N_thread=Threads.nthreads(),
        collector=Transducers.tcollect, will_plot=false, seed=2021,
    )
    fault_time = 0.0
    # single fault
    # rotor index ∈ {1, 2, 3, 4, 5, 6}
    # effectiveness ∈ [0, 1]
    _faults = 1:N |> Map(i -> [LoE(fault_time, rand(1:6), rand(1)[1])]) |> collect  # randomly sampled N faults
    # for trajectory parameters (terminal position constraint)
    multicopter = LeeHexacopter()  # dummy
    min_nt, max_nt = FTCTests.distribution_info(:hovering)
    # Control points of Bezier curve; randomly generated constant position tracking
    θs_array = 1:N |> Map(i -> [FTCTests.sample(multicopter, min_nt, max_nt)[1]]) |> collect  # sample(...)[1] corresponds to the position vector
    run_multiple_sim(N,
                     manoeuvres,
                     methods,
                     _faults,
                     θs_array,
                     t0, tf,
                     h_threshold, actual_time_limit, N_thread, collector,
                     will_plot, seed
                    )
end
