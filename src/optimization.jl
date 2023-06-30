"""Create a homogeneous vector by appending 1 to the end of a vector."""
HVJ(v) = vcat(v, 1)

# dispatch on GeometryStyle trait
function addhole2model!(model, hole::T, hindex, ipzmatricedict) where {T}
    return addhole2model!(GeometryStyle(T), model, hole, hindex, ipzmatricedict)
end

function addhole2model!(::IsFreeForm, model, hole, hindex, ipzmatricedict)
    error("Not yet implemented for FreeForm geometries")
end

function addhole2model!(::IsPrimitive, model, hole, hindex, ipzmatricedict)
    # access registered variables
    disth = model[:disth]
    dxy = model[:dxy]
    minAllowance = model[:minAllowance]

    pzn = getpartzeroname(hole)
    v_machined = getmachinedfeaturepoint(hole)
    v_rough = getroughfeaturepoint(hole)
    r_machined = getmachinedradius(hole)
    r_rough = getroughradius(hole)
    # equation (4)
    df_ = @expression(model, HVJ(v_machined)-ipzmatricedict[pzn]*HVJ(v_rough))
    @constraint(model, disth[hindex, 1:3] .== df_[1:3])
    # equation (5)
    @constraint(model, dxy[hindex]*dxy[hindex] >= disth[hindex, 1]*disth[hindex, 1]+disth[hindex, 2]*disth[hindex, 2])
    # equation (6)
    @constraint(model, r_machined - r_rough - dxy[hindex] >= minAllowance)
    return model
end

# dispatch on GeometryStyle trait
function addplane2model!(model, plane::T, pindex, ipzmatricedict) where {T}
    return addplane2model!(GeometryStyle(T), model, plane, pindex, ipzmatricedict)
end

function addplane2model!(::IsFreeForm, model, plane, pindex, ipzmatricedict)
    error("Not yet implemented for FreeForm geometries")
end

function addplane2model!(::IsPrimitive, model, plane, pindex, ipzmatricedict)
    # access registered variables
    distp = model[:disth]
    minAllowance = model[:minAllowance]
    
    pzn = getpartzeroname(plane)
    v_machined = getmachinedfeaturepoint(plane)
    v_rough = getroughfeaturepoint(plane)
    # equation (4)
    df_ = @expression(model, HVJ(v_machined)-ipzmatricedict[pzn]*HVJ(v_rough))
    @constraint(model, distp[pindex, 1:3] .== df_[1:3])
    # equation (7)
    @constraint(model, -1*distp[pindex,3] >= minAllowance)
    return model
end

function addtolerances2model!(model, mop::MultiOperationProblem, pzmatricedict)
    for (i, t) in enumerate(mop.tolerances)
        # access registered variables
        AbsValRelError = model[:AbsValRelError]

        # get features and part zero names
        f1 = getfeaturebyname(mop, t.featurename1)
        pzn1 = getpartzeroname(f1)
        f2 = getfeaturebyname(mop, t.featurename2)
        pzn2 = getpartzeroname(f2)

        # equation (2)
        v1 = @expression(model, t.ismachined1 ? pzmatricedict[pzn1]*HVJ(getmachinedfeaturepoint(f1)) : getroughfeaturepoint(f1))
        v2 = @expression(model, t.ismachined2 ? pzmatricedict[pzn2]*HVJ(getmachinedfeaturepoint(f2)) : getroughfeaturepoint(f2))
        e_t = @expression(model, v1[1:3]-v2[1:3])
        real_d = @expression(model, t.projection(e_t))

        # tolerance should be in interval if set to be used
        if mop.parameters["UseTolerances"]
            # equation (3)
            @constraint(model, t.lowervalue <= real_d <= t.uppervalue)
        end
        # equation (1)
        abs_dist = @expression(model, real_d - (t.lowervalue+t.uppervalue)/2)
        rel_dist = @expression(model, 2*abs_dist/(t.uppervalue-t.lowervalue))
        @constraint(model, rel_dist <= AbsValRelError[i])
        @constraint(model, rel_dist >= -1*AbsValRelError[i])
    end
    return model
end

function createjumpmodel(mop::MultiOperationProblem, optimizer)
    # create part zero variables
    "create invert partzero from jump variable"
    function makeipz(partzero, postr)
        iR = inv(partzero.rotation)
        miR = -1 * iR
        return vcat(hcat(iR, miR*[postr[1], postr[2], postr[3]]), [0 0 0 1])
    end

    model = Model(optimizer)

    partzeros = mop.partzeros
    pzr = 1:length(partzeros)
    # part zero positions: 3 long vectors
    @variable(model, pzpose[pzr, 1:3])
    # inverse part zero transformation matrices    
    ipzmatricedict = Dict([(partzeros[i].name, makeipz(partzeros[i], pzpose[i,1:3])) for i in pzr])
    # part zero transformation matrices
    pzmatrices = [vcat(hcat(pz.rotation, pzpose[i,1:3]), [0 0 0 1]) for (i, pz) in enumerate(partzeros)]
    pzmatricedict = Dict([(partzeros[i].name, pzmatrices[i]) for i in pzr])

    # holes that have machined state
    machinedholes = collectmachinedholes(mop)
    nholes = length(machinedholes)
    # planes that have machined state
    machinedplanes = collectmachinedplanes(mop)
    nplanes = length(machinedplanes)
    # numer of tolerances
    ntolerances = length(mop.tolerances)

    # variables: distance vectors
    @variable(model, disth[1:nholes, 1:3])
    @variable(model, distp[1:nplanes, 1:3])
    @variable(model, dxy[1:nholes] >= 0)
    # variable for absolute valued relative error for each tolerance
    @variable(model, AbsValRelError[1:ntolerances])
    # variable for minimum allowance
    @variable(model, minAllowance >= 0)

    ## tolerances
    addtolerances2model!(model, mop, pzmatricedict)

    # allowance for holes
    for (i, h) in enumerate(machinedholes)
        addhole2model!(model, h, i, ipzmatricedict)
    end
    # allowance for planes
    for (i, p) in enumerate(machinedplanes)
        addplane2model!(model, p, i, ipzmatricedict)
    end

    # optimization
    if mop.parameters["OptimizeForToleranceCenter"]
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

function optimizeproblem!(mop::MultiOperationProblem, model)
    model = createjumpmodel(mop, model)
    optimize!(model)
    setjumpresult!(mop, model)
    return mop
end
