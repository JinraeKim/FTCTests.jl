"""
    extract_fault_property(fault::LoE)

Extract LoE's fault property
"""
function extract_fault_property(fault::LoE)
    @unpack time, index, level = fault
    (; time=time, index=index, level=level,)
end

"""
faults can be a vector of `AbstractFault`s, e.g. FaultSet
"""
function extract_fault_property(faults::Vector{AbstractFault})
    faults |> Map(extract_fault_property) |> collect |> unique |> sort
end


"""
    get_fault_kind(faults::Vector{AbstractFault})

Get fault kind from `faults::Vector{AbstractFault}`.

# Notes
- failure: fully faulted
- fault: partially faulted
"""
function get_fault_kind(faults::Vector{AbstractFault})
    fault_kind = nothing
    # single fault or failure
    if length(faults) == 1
        fault = faults[1]
        @unpack index, level = fault
        # single failure
        if level == 0.0
            fault_kind = "single_failure_$(string(faults[1].index))"
        # single fault
        else
            fault_kind = "single_fault_$(string(faults[1].index))"
        end
    # double fault or failure
    elseif length(faults) == 2
        fault1, fault2 = faults
        # double fault or failure
        if fault1.level == fault2.level
            # double failure
            if fault1.level == 0.0
                fault_kind = "double_failure"
            # double fault
            else
                fault_kind = "double_fault"
            end
        # single fauliure and single fault
        else
            fault_kind = "single_failure_single_fault"
        end
    else
        error("Undefined fault kind")
    end
    fault_kind
end
