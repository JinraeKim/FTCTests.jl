module FTCTests

using Reexport
@reexport using FaultTolerantControl
const FTC = FaultTolerantControl
using UnPack
using Plots
using Transducers
using LinearAlgebra
using JLD2, FileIO
using Printf
using NumericalIntegration
using ReferenceFrameRotations
using StaticArrays: SMatrix
using DataFrames
using Random
using DifferentialEquations

# privileged name, see #7
TRAJ_DATA_NAME = "traj.jld2"


export run_sim, save_sim, plot_figures
export evaluate, extract_fault_property, get_fault_kind


include("run_sim.jl")
include("evaluate.jl")
include("fault_info.jl")


end
