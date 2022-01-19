using FTCTests
const FTC = FaultTolerantControl
using JLD2
using Transducers
using UnPack
using Flux
using Flux.Data: DataLoader
using LinearAlgebra


function faults_to_effectiveness(faults; dim_input=6, _fault_time=0.0)
    # actuator faults
    actuator_faults = faults |> Filter(fault -> typeof(fault) <: AbstractActuatorFault) |> collect
    actuator_fault_times = actuator_faults |> Map(fault -> fault.time) |> collect
    @assert actuator_fault_times == _fault_time*ones(size(actuator_fault_times)...)  # fault time: assumed to be zero
    affect_actuator! = FTC.Affect!(AbstractActuatorFault[actuator_faults...])
    # effectiveness matrix
    Λ = ones(dim_input) |> diagm
    affect_actuator!(Λ, _fault_time)
    λ = diag(Λ)
end

function preprocess(file_path::String; cf=PositionAngularVelocityCostFunctional(), verbose=true)
    if file_path[end-4:end] == ".jld2"
        jld2 = JLD2.load(file_path)
        @unpack df, traj_des, faults = jld2
        @assert length(faults) == 1  # currently, only single fault is considered
        λ = faults_to_effectiveness(faults)
        ts = df.time
        poss = df.sol |> Map(datum -> datum.plant.state.p) |> collect
        poss_des = ts |> Map(traj_des) |> collect
        e_ps = poss .- poss_des
        if verbose
            @warn("TODO: there is no desired angular velocity")
        end
        e_ωs = ts |> Map(t -> zeros(3)) |> collect
        J = cost(cf, ts, e_ps, e_ωs)
        return (; λ=λ, J=J)
    else
        if verbose
            @warn("ignored; the file's extension is not .jld2")
        end
        missing
    end
end

function preprocess(file_paths::Vector{String}; cf=PositionAngularVelocityCostFunctional(), verbose=true)
    data = file_paths |> Map(path -> preprocess(path; cf=cf, verbose=verbose)) |> collect
    data_filtered = filter(x -> typeof(x) != Missing, data)
end


function training_test(Ĵ, data_train, data_test, epochs)
    _data_train = make_a_trainable(data_train)
    _data_test = make_a_trainable(data_test)
    loss(d) = Flux.Losses.mse(Ĵ(d.λ), d.J)
    opt = ADAM(1e-3)
    ps = Flux.params(Ĵ)
    dataloader = DataLoader(_data_train; batchsize=16, shuffle=true, partial=false)
    println("Training $(epochs) epoch...")
    for epoch in 0:epochs
        println("epoch: $(epoch)/$(epochs)")
        println("train loss: $(loss(_data_train)), test loss: $(loss(_data_test))")
        if epoch != 0
            for d in dataloader
                train_loss, back = Flux.Zygote.pullback(() -> loss(d), ps)
                gs = back(one(train_loss))
                Flux.update!(opt, ps, gs)
            end
        end
    end
end

function make_a_trainable(data)
    λs = data |> Map(datum -> datum.λ) |> collect
    Js = data |> Map(datum -> datum.J) |> collect
    _data = (;
             λ = hcat(λs...),
             J = hcat(Js...),
            )  # for Flux
end


function main(; dir_log="data/debug/adaptive")
    # load data
    file_paths = readdir(dir_log; join=true)
    data = preprocess(file_paths; verbose=false)
    # construct approximator
    n_λ = 6
    n = n_λ  # total dim
    n_h = 64  # hidden layer nodes
    Ĵ = Chain(
              Dense(n, n_h, leakyrelu),
              Dense(n_h, n_h, leakyrelu),
              Dense(n_h, 1, leakyrelu),
             )
    data_train, data_test = partitionTrainTest(data, 0.9)  # 90:10
    epochs = 30
    training_test(Ĵ, data_train, data_test, epochs)
end
