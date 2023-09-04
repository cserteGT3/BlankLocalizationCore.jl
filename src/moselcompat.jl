export genmoseldat

"""
    partzero2numbers(partzero::PartZero)

Only for dat file generation. Get the part zero as array of 1,2,3-s.

# Example

```julia-repl
julia> tz2 = PartZero("test2", [0,1,1],  [-1  0  0; 0 0 1; 0 1 0], 2)

julia> BlankLocalization.partzero2numbers(tz2)
3-element Vector{Int64}:
 -1
  3
  2
```
"""
function partzero2numbers(partzero::PartZero)
    function whichaxis(v)
        for (i, v) in enumerate(v)
            isapprox(abs(v), 1) && return v < 0 ? -i : i
        end
    end
    return [whichaxis(partzero.rotation[:,i]) for i in 1:3]
end

struct DatFileToleranceRecord
    partzeroID1::Int
    axisID1::Int
    coordinate1::Float64
    isrough1::Bool
    partzeroID2::Int
    axisID2::Int
    coordinate2::Float64
    isrough2::Bool
    minval::Float64
    maxval::Float64
end

"""
    getcoordinateindatumorientation(partzero::PartZero, v, axis::Int)

Get the `axis`th coordinate of vector `v` in the orientation of the workpiece datum.
(Inverse transformed with the part zero, the part zero's position being zero.)
"""
function getcoordinateindatumorientation(partzero::PartZero, v, axis::Int)
    M = getpartzeroHM(partzero)
    M[1:3,4] = [0,0,0]
    #iM = inv(M)
    fv = M*vcat(v, 1)
    # not sure why, but part zero is needed, not its inverted part
    #fv = iM*vcat(v, 1)
    return fv[axis]
end

function roughtuple(feature, axis)
    v = getroughfeaturepoint(feature)
    return (pzid=-1, axisid=-1, coord=v[axis], rough=true,)
end

function partzeroindex(partzeros, partzeroname)
    for (i, pz) in enumerate(partzeros)
        if pz.name == partzeroname
            return i
        end
    end
    return nothing
end

function tolerancetuple2dattuple(mop::MultiOperationProblem, ifmachined::Bool, name::String, axis::Int)
    f = getfeaturebyname(mop, name)
    # for rough features only the rough (measured) coordinate is returned
    if ! ifmachined
        return roughtuple(f, axis)
    end
    # common for planes and holes
    pz = getpartzero(f)
    v = getmachinedfeaturepoint(f)
    coordinate = getcoordinateindatumorientation(pz, v, axis)
    pzid = partzeroindex(mop.partzeros, pz.name)
    return (pzid=pzid, axisid=axis, coord=coordinate, rough=false,)
end

function funcnametoaxis(func)
    if nameof(func) == :xfunc
        return 1
    elseif nameof(func) == :yfunc
        return 2
    else
        return 3
    end
end

function tolerances2dattolerances(mop)
    dtolerances = DatFileToleranceRecord[]

    for tol in mop.tolerances
        a = funcnametoaxis(tol.projection)
        f1 = tolerancetuple2dattuple(mop, tol.ismachined1, tol.featurename1, a)
        f2 = tolerancetuple2dattuple(mop, tol.ismachined2, tol.featurename2, a)
        push!(dtolerances, DatFileToleranceRecord(f1.pzid, f1.axisid, f1.coord, f1.rough,
            f2.pzid, f2.axisid, f2.coord, f2.rough,
            tol.lowervalue, tol.uppervalue))
    end
    return dtolerances
end

function genmoseldat(mop::MultiOperationProblem, fname="knorr-optim-test.dat")
    # holes that have machined state
    machinedholes = collectmachinedholes(mop)
    # planes that have machined state
    machinedplanes = collectmachinedplanes(mop)
    # numer of tolerances
    ntolerances = length(mop.tolerances)

    nplanes = length(machinedplanes)
    nholes = length(machinedholes)
    
    pard = Dict("nMachinedPlane"=> nplanes,
    "nMachinedHole"=>nholes, "nPartZero"=>length(mop.partzeros),
    "nTolerance"=>ntolerances, "nRoughHole"=>nholes,
    "nRoughPlane"=>nplanes,
    "chooseUseTolerances" => mop.parameters["UseTolerances"],
    "chooseGoodCastedModel" => mop.parameters["OptimizeForToleranceCenter"],
    "minAllowance" => mop.parameters["minAllowance"])
    open(fname, "w") do fio
        # parameters
        for (k,v) in pard
            println(fio, "'", k, "'", ":", v)
        end
        
        println(fio, "")

        # part zeros
        println(fio, "'partZeros':[")
        for pz in mop.partzeros
            pza = partzero2numbers(pz)
            println(fio, "[[", pza[1], " ", pza[2], " ", pza[3], "] '", pz.name, "']")
        end
        println(fio, "]\n")

        # machined planes
        println(fio, "'machinedPlanes':[")
        for (i, pl) in enumerate(machinedplanes)
            mv = getmachinedfeaturepoint(pl)
            pzid = partzeroindex(mop.partzeros, getpartzeroname(getpartzero(pl)))
            println(fio, "[", mv[3], " ", pzid, "]")
        end
        println(fio, "]\n")
        
        # rough planes
        println(fio, "'roughPlanes':[")
        for (i, pl) in enumerate(machinedplanes)
            rv = getroughfeaturepoint(pl)
            println(fio, "[[", rv[1], " ", rv[2], " ", rv[3], "] ", i, "]")
        end
        println(fio, "]\n")

        # machined holes
        println(fio, "'machinedHoles':[")
        for (i, h) in enumerate(machinedholes)
            mv = getmachinedfeaturepoint(h)
            mr = getmachinedradius(h)
            pzid = partzeroindex(mop.partzeros, getpartzeroname(getpartzero(h)))
            println(fio, "[[", mv[1], " ", mv[2], " ", mv[3], "] ", mr, " false true ", pzid, "]")
        end
        println(fio, "]\n")

        # rough holes
        println(fio, "'roughHoles':[")
        for (i, h) in enumerate(machinedholes)
            rv = getroughfeaturepoint(h)
            rr = getroughradius(h)
            println(fio, "[[", rv[1], " ", rv[2], " ", rv[3], "] ", rr, " ", i, "]")
        end
        println(fio, "]\n")

        # tolerances
        dtols = tolerances2dattolerances(mop)
        println(fio, "'tolerances':[")
        for t in dtols
            print(fio, "[")
            for i in 1:9
                print(fio, getfield(t, i), " ")
            end
            println(fio, getfield(t, 10), "]")
        end
        println(fio, "]\n")

    end

end
