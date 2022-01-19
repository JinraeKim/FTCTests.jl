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


# simulation
export run_sim, run_multiple_sim
# utils
export evaluate, extract_fault_property, get_fault_kind
# data manipulation
export partitionTrainTest


include("data_manipulation.jl")
include("run_sim.jl")
include("run_multiple_sim.jl")
include("evaluate.jl")
include("fault_info.jl")


end
