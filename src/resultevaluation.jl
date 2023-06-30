const NOTHING3 = [nothing, nothing, nothing]

function allowancetable(mop::MultiOperationProblem)
    df = DataFrame(name=String[], partzeroname=String[], machinedx=FON[], machinedy=FON[],
        machinedz=FON[], roughx=FON[], roughy=FON[], roughz=FON[], machinedr=FON[],
        roughr=FON[], xydistance=FON[], zdistance=FON[], rallowance=FON[],
        axallowance=FON[])
    # holes
    for h in mop.holes
        # rough radius and pose in datum
        r_r = hasrough(h) ? getroughradius(h) : nothing
        v_r = hasrough(h) ? getroughfeaturepoint(h) : NOTHING3
        
        # machined radius and pose in datum
        if hasmachined(h)
            r_m = hasmachined(h) ? getmachinedradius(h) : nothing
            v_m = hasmachined(h) ? getmachinedfeaturepointindatum(h) : nothing
            # partzero
            pz = getpartzero(h)
            T_inv = getpartzeroinverseHM(pz)
            d_f = HV(v_m) - T_inv*HV(v_r)
            xydist = norm(d_f[1:2])
            zdist = d_f[3]
            rallowance = r_m - r_r - xydist
            zallowance = -zdist
        else
            r_m = nothing
            v_m = NOTHING3
            xydist = nothing
            zdist = nothing
            rallowance = nothing
            zallowance = nothing
        end

        push!(df, [getfeaturename(h), getpartzeroname(h), v_m[1], v_m[2], v_m[3], v_r[1],
            v_r[2], v_r[3], r_m, r_r, xydist, zdist, rallowance, zallowance])
    end
    # planes
    for p in mop.planes
        # rough radius and pose in datum
        v_r = hasrough(p) ? getroughfeaturepoint(p) : NOTHING3
        
        # machined radius and pose in datum
        if hasmachined(p)
            v_m = hasmachined(p) ? getmachinedfeaturepointindatum(p) : nothing
            # partzero
            pz = getpartzero(p)
            T_inv = getpartzeroinverseHM(pz)
            d_f = HV(v_m) - T_inv*HV(v_r)
            zdist = d_f[3]
            zallowance = -zdist
        else
            v_m = NOTHING3
            zdist = nothing
            zallowance = nothing
        end

        push!(df, [getfeaturename(p), getpartzeroname(p), v_m[1], v_m[2], v_m[3], v_r[1],
            v_r[2], v_r[3], nothing, nothing, nothing, zdist, nothing, zallowance])
    end
    return df
end

function minimumallowance(allowancedb)
    radial = minimum(filter(x->!isnothing(x), allowancedb.rallowance))
    axial = minimum(filter(x->!isnothing(x), allowancedb.axallowance))
    return (radial = radial, axial = axial)
end

function printallowancetable(mop::MultiOperationProblem; kwargs...)
    df = allowancetable(mop)
    printallowancetable(df; kwargs...)
end

function printallowancetable(df::DataFrame; title = "", printstat=true, fname="")
    mrad, max = minimumallowance(df)

    if printstat
        newtitle = string("Allowance table", title, " Min allowance radial: ",
        @sprintf("%.3f", mrad), " axial: ", @sprintf("%.3f", max))
    else
        newtitle = string("Allowance table", title)
    end

    commonprintoptions = (header=names(df), formatters=(ft_nonothing,), title=newtitle,
        title_alignment=:c, )

    if fname == ""
        pretty_table(df; backend=Val(:text), crop=:none, title_same_width_as_table=true,
            commonprintoptions...)
    elseif contains(fname, ".html")
        open(fname, "w") do io
            pretty_table(io, df; backend=Val(:html), tf = tf_html_minimalist)
        end
    end

end

function tolerancetable(mop::MultiOperationProblem)
    """modify a tolerance's names based on if the features are rough or machined"""
    function fnameplusrORm(t)
        fn1 = t.ismachined1 ? string("M ", t.featurename1) : string("R ", t.featurename1)
        fn2 = t.ismachined2 ? string("M ", t.featurename2) : string("R ", t.featurename2)
        return (fn1, fn2)
    end

    df = DataFrame(feature1=String[], partzero1=String[], feature2=String[],
    partzero2=String[], nominald=Float64[], lowerd=Float64[], upperd=Float64[],
    distance=Vector{Float64}[], reald=Float64[], tolerancefield=Float64[])
    
    for t in mop.tolerances
        # get features and part zero names
        fname1, fname2 = fnameplusrORm(t)
        f1 = getfeaturebyname(mop, t.featurename1)
        pzn1 = getpartzeroname(f1)
        f2 = getfeaturebyname(mop, t.featurename2)
        pzn2 = getpartzeroname(f2)

        v1 = t.ismachined1 ? getmachinedfeaturepointindatum(f1) : getroughfeaturepoint(f1)
        v2 = t.ismachined2 ? getmachinedfeaturepointindatum(f2) : getroughfeaturepoint(f2)
        e_t = v1[1:3] - v2[1:3]
        real_d = t.projection(e_t)
        abs_d = real_d - (t.lowervalue+t.uppervalue)/2
        rel_d = 2*abs_d/(t.uppervalue-t.lowervalue)*100

        push!(df, [fname1, pzn1, fname2, pzn2, t.nominalvalue, t.lowervalue, t.uppervalue,
            e_t, real_d, rel_d])
    end
    return df
end

function avgreltolerror(tolerancedb)
    return sum(abs.(tolerancedb.tolerancefield))/nrow(tolerancedb)
end

function printtolerancetable(mop::MultiOperationProblem; kwargs...)
    df = tolerancetable(mop)
    printtolerancetable(df; kwargs...)
end

function printtolerancetable(df::DataFrame; title = "", printstat=true, fname="")
    function niceify_tolerance(value)
        tl = length("tolerancefield")-2
        vstr = string(@sprintf("%.1f", value), " %")
        if (value <= -100)
            return "!-"*lpad(vstr, tl-2)
        elseif (100 <= value)
            return "!+"*lpad(vstr, tl-2)
        else
            return lpad(vstr, tl)
        end
    end
    if printstat
        newtitle = string("Tolerance table", title, " avgabsreltolerror: ",
        @sprintf("%.1f", avgreltolerror(df)), "%")
    else
        newtitle = string("Tolerance table", title)
    end
    df[!, :tolerancefield] = niceify_tolerance.(df[!, :tolerancefield])

    commonprintoptions = (header=names(df), formatters=(ft_nonothing,), title=newtitle,
        title_alignment=:c, show_row_number=true, row_number_column_title="Tol #")

    if fname == ""
        pretty_table(df; backend=Val(:text), crop=:none, title_same_width_as_table=true,
            commonprintoptions...)
    elseif contains(fname, ".html")
        open(fname, "w") do io
            pretty_table(io, df; backend=Val(:html), tf = tf_html_minimalist)
        end
    end

end