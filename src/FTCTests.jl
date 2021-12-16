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


export run_sim


include("run_sim.jl")
include("evaluate.jl")


end
