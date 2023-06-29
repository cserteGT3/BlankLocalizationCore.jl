# dispatch on GeometryStyle trait
function addhole2model!(model, hole::T, hindex, ipzmatrices) where {T}
    return addhole2model!(GeometryStyle(T), model, hole, hindex, ipzmatrices)
end

function addhole2model!(::IsFreeForm, model, hole, hindex, ipzmatrices)
    error("Not yet implemented for FreeForm geometries")
end

function addhole2model!(::IsPrimitive, model, hole, hindex, ipzmatrices)
    pzn = getpartzeroname(h)
    df_ = @expression(model, HV(getmachinedv(h))-ipzmatrices[pzn]*HV(getroughv(h)))
    @constraint(model, disth[i, 1:3] .== df_[1:3])
    @constraint(model, dxy[i]*dxy[i] >= disth[i, 1]*disth[i, 1]+disth[i, 2]*disth[i, 2])
    @constraint(model, getmachinedd(h)/2 - getroughd(h)/2 - dxy[i] >= minAllowance)
    return model
end

function addplanes2model!(model, mop::MultiOperationProblem, ipzmatrices)

end

function createopt(mop::MultiOperationProblem, model)
    # create part zero variables
    "create invert partzero from jump variable"
    function makeipz(partzero, postr)
        iR = inv(partzero.rotation)
        miR = -1 * iR
        return vcat(hcat(iR, miR*[postr[1], postr[2], postr[3]]), [0 0 0 1])
    end
    partzeros = mop.partzeros
    pzi = 1:length(partzeros)
    # part zero positions: 3 long vectors
    # and part zero matrixes
    @variable(model, pzpose[pzi, 1:3])
    ipzmatrices = Dict([(partzeros[i].name, makeipz(partzeros[i], pzpose[i,1:3])) for i in pzi])
    
    machinedholes = collectmachinedholes(mop)
    nholes = length(machinedholes)
    
    # machined holes and planes
    mholes = getmachinedholes(mop)
    mplanes = getmachinedplanes(mop)
    tolerances = generatedattolerance(mop)
    nplanes = length(mplanes)
    ntolerances = length(tolerances)
    # distance vectors
    @variable(model, disth[1:nholes, 1:3])
    @variable(model, distp[1:nplanes, 1:3])
    @variable(model, dxy[1:nholes] >= 0)
    # this one is from mosel
    @variable(model, AbsValRelError[1:ntolerances])
    # allowance for good/bad model
    @variable(model, minAllowance >= 0)

    ## tolerances
    for (i, t) in enumerate(tolerances)
        if t.isrough1
            real_d = @expression(model, t.coordinate1 - (pzpose[t.partzeroID2, t.axisID2] + t.coordinate2))
        elseif t.isrough2
            real_d = @expression(model, (pzpose[t.partzeroID1, t.axisID1] + t.coordinate1) - t.coordinate2)
        else
            real_d = @expression(model, (pzpose[t.partzeroID1, t.axisID1] + t.coordinate1) - (pzpose[t.partzeroID2, t.axisID2] + t.coordinate2))
        end
        # tolerance should be in interval if set to be used
        if mop.parameters["chooseUseTolerances"]
            @constraint(model, t.minval <= real_d <= t.maxval)
        end
        abs_dist = @expression(model, real_d - (t.minval+t.maxval)/2)
        rel_dist = @expression(model, 2*abs_dist/(t.maxval-t.minval))
        @constraint(model, rel_dist <= AbsValRelError[i])
        @constraint(model, rel_dist >= -1*AbsValRelError[i])
    end

    # allowance
    #new:
    for (i, h) in enumerate(machinedholes)
        addhole2model!(model, h, i, ipzmatrices)
    end
    #old:
    for (i, h) in enumerate(mholes)
        pzn = getpartzero(h).name
        df_ = @expression(model, HV(getmachinedv(h))-ipzmatrices[pzn]*HV(getroughv(h)))
        @constraint(model, disth[i, 1:3] .== df_[1:3])
        @constraint(model, dxy[i]*dxy[i] >= disth[i, 1]*disth[i, 1]+disth[i, 2]*disth[i, 2])
        if largerCNC(h)
            @constraint(model, getmachinedd(h)/2 - getroughd(h)/2 - dxy[i] >= minAllowance)
        else
            @constraint(model, getroughd(h)/2 - getmachinedd(h)/2 - dxy[i] >= minAllowance)
        end
        if validz(h)
            @constraint(model, -1*disth[i,3]>= minAllowance)
        end
    end

    for (i, p) in enumerate(mplanes)
        pzn = getpartzero(p).name
        df_ = @expression(model, HV(getmachinedv(p))-ipzmatrices[pzn]*HV(getroughv(p)))
        @constraint(model, distp[i, 1:3] .== df_[1:3])
        @constraint(model, -1*distp[i,3]>= minAllowance)
    end

    # optimization
    if mop.parameters["chooseGoodCastedModel"]
        @constraint(model, minAllowance>=mop.parameters["minAllowance"])
        @objective(model, Min, sum(AbsValRelError))
    else
        @objective(model, Max, minAllowance)
    end

    return model
end

function setjumpresult!(mop::MultiOperationProblem, jump_model)
    status = termination_status(jump_model)
    if status != TerminationStatusCode(1)
        @warn "Optimization did not find optimum! Ignoring result. Status: $status"
        return mop
    end
    jump_result = value.(jump_model[:pzpose])
    for (i, pz) in enumerate(mop.partzeros)
        for j in 1:3
            pz.position[j] = jump_result[i, j]
        end
    end
    jump_status = string(termination_status(jump_model))
    jump_minallowance = value(jump_model[:minAllowance])
    or = OptimizationResult(jump_status, jump_minallowance)
    mop.opresult = or
    return mop
end
