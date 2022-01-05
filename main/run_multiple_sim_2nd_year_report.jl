using FTCTests  # reexport FaulTolerantControl
using Transducers
using Random
using Test


"""
This is used for 2nd-year report.
"""
function run_multiple_sim_2nd_year_report(N=1;
        manoeuvres=[:hovering, :forward],
        methods=[:adaptive, :adaptive2optim],
        t0=0.0, tf=20.0,
        h_threshold=5.0,  # m (nothing: no constraint)
        actual_time_limit=60.0,  # s
        N_thread=Threads.nthreads(),
        collector=Transducers.tcollect, will_plot=false, seed=2021,
    )
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
    θs = [[0, 0, -10.0]]  # Control points of Bezier curve; constant position tracking
    θs_array = 1:N |> Map(i -> θs) |> collect
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
