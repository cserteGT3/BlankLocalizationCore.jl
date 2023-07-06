"""
    OptimizationResult

Store the status (result) of an optimization run and the minimum allowance value.
"""
struct OptimizationResult
    status::String
    minallowance::Float64
end

function Base.show(io::IO, or::OptimizationResult)
    print(io, or.status, ", minimum allowance: ", or.minallowance)
end

emptyor() = OptimizationResult("empty", 0.0)

struct Tolerance
    featurename1::String
    ismachined1::Bool
    projection::Function
    featurename2::String
    ismachined2::Bool
    nominalvalue::Float64
    lowervalue::Float64
    uppervalue::Float64
    note::String
end

mutable struct MultiOperationProblem
    partzeros::Vector{PartZero}
    holes::Vector{HoleLocalizationFeature}
    planes::Vector{PlaneLocalizationFeature}
    tolerances::Vector{Tolerance}
    parameters::Dict{String,Real}
    opresult::OptimizationResult
end

function MultiOperationProblem(partzeros, holes, planes, tolerances, parameters)
    return MultiOperationProblem(partzeros, holes, planes, tolerances, parameters, emptyor())
end

function problemtype(mop::MultiOperationProblem)
    # problem type is depending on the rough geometries: IsPrimitive or IsFreeForm
    # if there is at least one IsFreeForm rough geometry -> hybrid problem
    holetypes = GeometryStyle.(typeof.(x.rough for x in mop.holes))
    for ht in holetypes
        ht === IsFreeForm() && return :HybridProblem
    end
    planetypes = GeometryStyle.(typeof.(x.rough for x in mop.planes))
    for pt in planetypes
        pt === IsFreeForm() && return :HybridProblem
    end
    return :PrimitiveProblem
end

function Base.show(io::IO, mop::MultiOperationProblem)
    nh = size(mop.holes, 1)
    np = size(mop.planes, 1)
    npz = size(mop.partzeros, 1)
    nts = size(mop.tolerances, 1)
    sn = string(problemtype(mop))
    print(io, sn,": ",
    npz," part zero", npz > 1 ? "s, " : ", ",
    nh," hole", nh > 1 ? "s, " : ", ",
    np," plane", np > 1 ? "s, " : ", ",
    nts," tolerance", nts > 1 ? "s" : "",
    ", status: ", mop.opresult.status)
end

"""
    printpartzeropositions(mop::MultiOperationProblem)

Print the positions of the part zeros of a `MultiOperationProblem`.
"""
printpartzeropositions(mop::MultiOperationProblem) = printpartzeropositions(mop.partzeros)

"""
    setparameters!(mop::MultiOperationProblem, pardict)

Set parameter dictionary of a `MultiOperationProblem` to `pardict`.
"""
function setparameters!(mop::MultiOperationProblem, pardict)
    mop.parameters = pardict
    return mop
end

"""
    getfeaturebyname(mop::MultiOperationProblem, featurename)

Get a hole or plane feature by its name.
It is assumed that all features have distinct names.
Return `nothing`, if no feature is found with `featurename`.
"""
function getfeaturebyname(mop::MultiOperationProblem, featurename)
    function retbyname(array, name)
        for f in array
            if getfeaturename(f) == name
                return f
            end
        end
        return nothing
    end

    hole_ = retbyname(mop.holes, featurename)
    isnothing(hole_) || return hole_
    # return plane even if it is nothing
    return retbyname(mop.planes, featurename)
end

"""
    collectholesbypartzero(mop::MultiOperationProblem, partzeroname)

Collect holes that are grouped to part zero called `partzeroname`.
"""
function getholesbypartzero(mop::MultiOperationProblem, partzeroname)
    return filter(x->getpartzeroname(x) == partzeroname, mop.holes)
end

"""
    collectmachinedholes(mop::MultiOperationProblem)

Collect holes that have a machined state.
"""
collectmachinedholes(mop::MultiOperationProblem) = filter(hasmachined, mop.holes)

"""
    collectmachinedplanes(mop::MultiOperationProblem)

Collect planes that have a machined state.
"""
collectmachinedplanes(mop::MultiOperationProblem) = filter(hasmachined, mop.planes)

"""
    collectroughholes(mop::MultiOperationProblem)

Collect those holes, that have rough stage.
"""
collectroughholes(mop::MultiOperationProblem) = filter(hasrough, mop.holes)

"""
    collectroughplanes(mop::MultiOperationProblem)

Collect those planes, that have rough stage.
"""
collectroughplanes(mop::MultiOperationProblem) = filter(hasrough, mop.planes)
