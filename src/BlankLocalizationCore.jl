module BlankLocalizationCore

using JuMP
using HomogeneousVectors: HV

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
        

include("partzeros.jl")
include("geometries.jl")
include("optimization.jl")

end
