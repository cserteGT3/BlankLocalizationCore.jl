module BlankLocalizationCore

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
        MultiOperationProblem
        

include("partzeros.jl")
include("geometries.jl")

end
