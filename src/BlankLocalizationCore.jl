module BlankLocalizationCore

using JuMP
using DataFrames: DataFrame, names, nrow
using PrettyTables: pretty_table, ft_nonothing, tf_html_minimalist
using Rotations: RotMatrix
using Meshes: SimpleMesh, vertices, boundingbox, connect, Point3, Vec3, Plane, Cylinder,
    Rotate, Translate, Disk
using Logging: @warn
using LinearAlgebra: norm, cross, normalize, normalize!
using Printf: @sprintf

export  PartZero,
        printpartzeropositions

export  AbstractHoleGeometry,
        AbstractPlaneGeometry,
        GeometryStyle,
        IsPrimitive,
        IsFreeForm,
        surfacepoints,
        filteredsurfacepoints,
        featurepoint,
        featureradius,
        visualizationgeometry,
        SimpleHole,
        HoleAndNormal,
        SimplePlane,
        PlaneAndNormal,
        MeshHole,
        MeshPlane,
        FeatureDescriptor,
        LocalizationFeature,
        HoleLocalizationFeature,
        PlaneLocalizationFeature,
        localizationfeature,
        OptimizationResult,
        Tolerance,
        MultiOperationProblem,
        setparameters!,
        isoptimum

export  createjumpmodel,
        setjumpresult!,
        optimizeproblem!

export  allowancetable,
        minimumallowance,
        printallowancetable,
        tolerancetable,
        toleranceerror,
        printtolerancetable

export  genroughholes,
        genmachinedholes,
        genroughplanes,
        genmachinedplanes

"""Union type for `Float64` and `Nothing`."""
const FON = Union{Nothing,Float64}

"""A 3 long vector of `nothing`s."""
const NOTHING3 = [nothing, nothing, nothing]

"""Create a homogeneous vector by appending 1 to the end of a vector."""
HV(v) = vcat(v, 1)

include("partzeros.jl")
include("geometries.jl")
include("optimization.jl")
include("resultevaluation.jl")
include("visualization.jl")

end
