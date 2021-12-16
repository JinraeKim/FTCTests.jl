using FTCTests
using Transducers


N = 1
run_multiple_sim(N; collector=Transducers.tcollect, will_plot=false, seed=2021)
