using FTCTests
using JLD2
using UnPack
using DataFrames
using Statistics
using Transducers


function _file_path_to_nt(file_path::String, t1, threshold)
    jld2 = JLD2.load(file_path)
    @unpack faults, fdi, simulation_height_success, simulation_actual_time_success = jld2
    if simulation_actual_time_success == true
        if simulation_height_success == false
            is_success = false
        else
            is_success = evaluate(jld2, t1, threshold)
        end
    else
        is_success = false  # dummy value
    end
    _nt = (;
           fault=extract_fault_property(faults),
           fault_kind=get_fault_kind(faults),
           fdi_delay=fdi.τ,
           is_success=is_success,
           sim_time_success=simulation_actual_time_success,
          )
end


function compute_recovery_rate(; _dir_log="data", t1=15.0, threshold=0.1)
    df = DataFrame()
    for manoeuvre in [:hovering, :forward]
        for method in [:adaptive, :adaptive2optim]
            _df = DataFrame()
            dir_log = joinpath(joinpath(_dir_log, String(manoeuvre)), String(method))
            file_paths = readdir(dir_log; join=true)
            _ = file_paths |> Map(file_path ->
                                  push!(_df, _file_path_to_nt(file_path, t1, threshold))
                                 ) |> collect
            _df_simtime = filter(:sim_time_success => t -> t == true, _df)
            # group by FDI delay
            groups_delay = groupby(_df_simtime, :fdi_delay)
            for df_delay in groups_delay
                # group by fault kind
                groups_fault_kind = groupby(df_delay, :fault_kind)
                for df_fault_kind in groups_fault_kind
                    recovery_rate = mean(df_fault_kind.is_success)
                    push!(df, (;
                               manoeuvre=manoeuvre,
                               method=method,
                               delay=df_delay.fdi_delay[1],
                               fault_kind=df_fault_kind.fault_kind[1],  # the same fault kind
                               recovery_rate=recovery_rate,
                               num=length(df_fault_kind.is_success)
                              ))
                end
            end
        end
    end
    df
end
