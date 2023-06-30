module BlankLocalizationCore

using JuMP
using Logging: @warn

export  PartZero,
        printpartzeropositions

export  SimpleHole,
        SimplePlane,
        MeshHole,
        MeshPlane,
        FeatureDescriptor,
        HoleLocalizationFeature,
        PlaneLocalizationFeature,
        OptimizationResult,
        Tolerance,
        MultiOperationProblem

export  createjumpmodel,
        setjumpresult!,
        optimizeproblem!

include("partzeros.jl")
include("geometries.jl")
include("optimization.jl")

end
