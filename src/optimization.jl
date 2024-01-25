function addallowancedfeature2model!(model, f, ipzmatricedict)
    # dispatch on: primitive/free-form and planar/cylindrical
    addallowancedfeature2model!(RepresentationStyle(f), FeatureStyle(f), model, f, ipzmatricedict)
end

function addallowancedfeature2model!(::Primitive, ::Cylindrical, model, feature, ipzmatricedict)
    # access registered variables
    minAllowance = model[:minAllowance]

    # register distance variable:
    dxy = @variable(model, base_name = string("d_xy_", featurename(feature)), lower_bound = 0.0)

    pzn = partzeroname(feature)
    # featurepoints are Meshes.Point
    v_machined_ = machinedfeaturepoint(feature)
    v_machined = [v_machined_.coords.coords...]
    v_rough_ = roughfeaturepoint(feature)
    v_rough = [v_rough_.coords.coords...]
    r_machined = machinedradius(feature)
    r_rough = roughradius(feature)
    # equation (4)
    d_f = @expression(model, HV(v_machined)-ipzmatricedict[pzn]*HV(v_rough))
    # equation (5)
    @constraint(model, dxy*dxy >= d_f[1]*d_f[1] + d_f[2]*d_f[2])
    # equation (6)
    @constraint(model, r_machined - r_rough - dxy >= minAllowance)
    return model
end

function addallowancedfeature2model!(::Primitive, ::Planar, model, feature, ipzmatricedict)
    # access registered variables
    minAllowance = model[:minAllowance]
    maxPlaneZAllowance = model[:maxPlaneZAllowance]

    # register distance variable:
    dz = @variable(model, base_name = string("d_z_", featurename(feature)))
    
    pzn = partzeroname(feature)
    v_machined_ = machinedfeaturepoint(feature)
    v_machined = [v_machined_.coords.coords...]
    v_rough_ = roughfeaturepoint(feature)
    v_rough = [v_rough_.coords.coords...]

    # equation (4)
    d_f = @expression(model, HV(v_machined)-ipzmatricedict[pzn]*HV(v_rough))
    @constraint(model, dz == d_f[3])
    # equation (7)
    @constraint(model, -1*dz >= minAllowance)
    @constraint(model, -1*dz <= maxPlaneZAllowance)
    return model
end

function addallowancedfeature2model!(::FreeForm, ::Cylindrical, model, feature, ipzmatricedict)
    # access registered variables
    minAllowance = model[:minAllowance]
    
    # filtered surface points of a free form surface
    qs = roughfilteredsurfacepoints(feature)
    qiter = 1:length(qs)
    
    # register distance variable:
    dxy = @variable(model, [qiter], base_name = string("d_xy_", getfeaturename(feature)), lower_bound = 0.0)
    
    pzn = partzeroname(feature)
    v_machined_ = machinedfeaturepoint(feature)
    v_machined = [v_machined_.coords.coords...]
    r_machined = machinedradius(feature)
    # equation (4)
    for (i, qmeshes) in enumerate(qs)
        q = [qmeshes.coords.coords...]
        d_f = @expression(model, HV(v_machined)-ipzmatricedict[pzn]*HV(q))
        # equation (5)
        @constraint(model, dxy[i]*dxy[i] >= d_f[1]*d_f[1] + d_f[2]*d_f[2])
        # equation (6)
        @constraint(model, r_machined - dxy[i] >= minAllowance)
    end
    return model
end

function addallowancedfeature2model!(::FreeForm, ::Planar, model, feature, ipzmatricedict)
    # access registered variables
    minAllowance = model[:minAllowance]
    maxPlaneZAllowance = model[:maxPlaneZAllowance]

    # filtered surface points of a free form surface
    qs = getroughfilteredpoints(feature)
    qiter = 1:length(qs)

    # register distance variable:
    dz = @variable(model, [qiter], base_name = string("d_z_", featurename(feature)))

    pzn = partzeroname(feature)
    v_machined_ = machinedfeaturepoint(feature)
    v_machined = [v_machined_.coords.coords...]
    # equation (4)
    for (i, qmeshes) in enumerate(qs)
        q = [qmeshes.coords.coords...]
        d_f = @expression(model, HV(v_machined)-ipzmatricedict[pzn]*HV(q))
        # equation (5)
        @constraint(model, dz[i] == d_f[3])
        # equation (6)
        @constraint(model, -1*dz[i] >= minAllowance)
        @constraint(model, -1*dz[i] <= maxPlaneZAllowance)
    end
    return model
end

function addtolerances2model!(model, mop::MultiOperationProblem, pzmatricedict)
    for (i, t) in enumerate(mop.tolerances)
        function fpointexpr(feature::RoughFeature)
            v_ = featurepoint(feature)
            v = [v_.coords.coords...]
            return @expression(model, v)
        end
        function fpointexpr(feature::MachinedFeature)
            pzn = partzeroname(feature)
            v_ = featurepoint(feature)
            v = [v_.coords.coords...]
            return @expression(model, pzmatricedict[pzn]*HV(v))
        end

        # access registered variables
        AbsValRelError = model[:AbsValRelError]

        # equation (2)
        v1 = fpointexpr(datumfeature(t))
        v2 = fpointexpr(tolerancefeature(t))
        e_t = @expression(model, v1[1:3]-v2[1:3])
        pa = projectionaxis(t)
        real_d = @expression(model, dot(pa, e_t))

        # tolerance should be in interval if set to be used
        # get lower and upper values
        lv = minimumvalue(t)
        uv = maximumvalue(t)
        if mop.parameters["UseTolerances"]
            # equation (3)
            @constraint(model, lv <= real_d <= uv)
        end
        # equation (1)
        abs_dist = @expression(model, real_d - (lv+uv)/2)
        rel_dist = @expression(model, 2*abs_dist/(uv-lv))
        @constraint(model, rel_dist <= AbsValRelError[i])
        @constraint(model, rel_dist >= -1*AbsValRelError[i])
    end
    return model
end

function createjumpmodel(mop::MultiOperationProblem, optimizer; disable_string_names=false)
    # create part zero variables
    "create invert partzero from jump variable"
    function makeipz(partzero, postr)
        iR = inv(partzero.rotation)
        miR = -1 * iR
        return vcat(hcat(iR, miR*[postr[1], postr[2], postr[3]]), [0 0 0 1])
    end

    model = Model(optimizer)
    if disable_string_names
        set_string_names_on_creation(model, false)
    end

    partzeros = mop.partzeros
    pzr = 1:length(partzeros)
    # part zero positions: 3 long vectors
    @variable(model, pzpose[pzr, 1:3])
    # inverse part zero transformation matrices    
    ipzmatricedict = Dict([(partzeros[i].name, makeipz(partzeros[i], pzpose[i,1:3])) for i in pzr])
    # part zero transformation matrices
    pzmatrices = [vcat(hcat(pz.rotation, pzpose[i,1:3]), [0 0 0 1]) for (i, pz) in enumerate(partzeros)]
    pzmatricedict = Dict([(partzeros[i].name, pzmatrices[i]) for i in pzr])

    # numer of tolerances
    ntolerances = length(mop.tolerances)
    
    # variable for absolute valued relative error for each tolerance
    @variable(model, AbsValRelError[1:ntolerances])
    # variable for minimum allowance
    #@variable(model, minAllowance >= 0)
    @variable(model, minAllowance)
    # variable for maximum allowance for planes
    @variable(model, maxPlaneZAllowance)

    ## tolerances
    addtolerances2model!(model, mop, pzmatricedict)

    # allowances
    for f in mop.features
        addallowancedfeature2model!(model, f, ipzmatricedict)
    end

    # if maximum allowance of planes is given, then set it
    if haskey(mop.parameters, "maxPlaneZAllowance")
        @assert mop.parameters["maxPlaneZAllowance"] > mop.parameters["minAllowance"] "Maximum plane z allowance must be larger, than minimum allowance!"
        @constraint(model, maxPlaneZAllowance == mop.parameters["maxPlaneZAllowance"])
    end

    # optimization
    if mop.parameters["OptimizeForToleranceCenter"]
        @constraint(model, minAllowance>=mop.parameters["minAllowance"])
        @objective(model, Min, sum(AbsValRelError))
    else
        @objective(model, Max, minAllowance)
    end

    # set part zeros if option is provided
    if haskey(mop.parameters, "SetPartZeroPosition")
        predef_partzeros = mop.parameters["SetPartZeroPosition"]
        lpz = length(mop.partzeros)
        lpdz = length(predef_partzeros)
        if lpz == lpdz
            # for each part zero
            for i in pzr
                # ignore elements that are empty
                ith_pzpose = predef_partzeros[i]
                isempty(ith_pzpose) && continue
                for j in 1:3
                    isnan(ith_pzpose[j]) && continue
                    @constraint(model, pzpose[i, j] == ith_pzpose[j])
                end
            end
        else
            throw(DimensionMismatch("Length of `SetPartZeroPosition` ($lpdz) does not match number of part zeros ($lpz)!"))
        end
    end

    return model
end

function setjumpresult!(mop::MultiOperationProblem, jump_model)
    status = termination_status(jump_model)
    if (status != OPTIMAL) & (status != LOCALLY_SOLVED)
        mop.opresult = OptimizationResult(string(status), NaN)
        @warn "Optimization did not find optimum! Ignoring result. Status: $status"
        return mop
    end
    jump_result = value.(jump_model[:pzpose])
    for (i, pz) in enumerate(mop.partzeros)
        for j in 1:3
            pz.position[j] = jump_result[i, j]
        end
    end
    jump_status = string(status)
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
