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

"""
    isoptimum(or::OptimizationResult)

Tell if `or` is in an optimal solution state, either: `OPTIMAL` or `LOCALLY_SOLVED`.
"""
function isoptimum(or::OptimizationResult)
    return (or.status == "OPTIMAL") | (or.status == "LOCALLY_SOLVED")
end

mutable struct MultiOperationProblem
    partzeros::Vector{PartZero}
    features::Vector{LocalizationFeature} # features that have rough and machined -> allowanced
    tolerances::Vector{LocalizationTolerance}
    parameters::Dict{String,Real}
    opresult::OptimizationResult
end

function MultiOperationProblem(partzeros, features, tolerances, parameters)
    return MultiOperationProblem(partzeros, features, tolerances, parameters, emptyor())
end

function problemtype(mop::MultiOperationProblem)
    # problem type is depending on the rough geometries: IsPrimitive or IsFreeForm
    # if there is at least one IsFreeForm rough geometry -> hybrid problem
    featuretypes = GeometryStyle.(typeof.(x.rough for x in mop.features))
    for ft in featuretypes
        ft === IsFreeForm() && return :HybridProblem
    end
    return :PrimitiveProblem
end

function collectholefeatures(mop::MultiOperationProblem)
    filter(x->x isa HoleLocalizationFeature, mop.features)
end

function collectplanefeatures(mop::MultiOperationProblem)
    filter(x->x isa PlaneLocalizationFeature, mop.features)
end

function Base.show(io::IO, mop::MultiOperationProblem)
    nh = size(collectholefeatures(mop), 1)
    np = size(collectplanefeatures(mop), 1)
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
    isoptimum(mop::MultiOperationProblem)

Tell if `mop`'s solution is in an optimal state, either: `OPTIMAL` or `LOCALLY_SOLVED`.
"""
isoptimum(mop::MultiOperationProblem) = isoptimum(mop.opresult)

"""
    getfeaturebyname(mop::MultiOperationProblem, featurename)

Get a hole or plane feature by its name.
It is assumed that all features have distinct names.
Return `nothing`, if no feature is found with `featurename`.
"""
function getfeaturebyname(mop::MultiOperationProblem, featurename)
    for f in mop.features
        if getfeaturename(f) == featurename
            return f
        end
    end
    return nothing
end

"""
    collectfeaturesbypartzero(mop::MultiOperationProblem, partzeroname)

Collect features that are grouped to part zero called `partzeroname`.
"""
function collectfeaturesbypartzero(mop::MultiOperationProblem, partzeroname)
    return filter(x->getpartzeroname(x) == partzeroname, mop.features)
end
