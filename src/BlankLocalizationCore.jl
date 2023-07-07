module BlankLocalizationCore

using JuMP
using DataFrames: DataFrame, names, nrow
using PrettyTables: pretty_table, ft_nonothing, tf_html_minimalist
using Meshes: SimpleMesh, vertices, boundingbox
using Logging: @warn
using LinearAlgebra: norm, dot
using Statistics: mean
using Printf: @sprintf

export  PartZero,
        printpartzeropositions

export  SimpleHole,
        SimplePlane,
        MeshHole,
        MeshPlane,
        LocalizationFeature,
        HoleLocalizationFeature,
        PlaneLocalizationFeature
#=
export  OptimizationResult,
        Tolerance,
        MultiOperationProblem

export  createjumpmodel,
        setjumpresult!,
        optimizeproblem!

export  allowancetable,
        printallowancetable,
        tolerancetable,
        printtolerancetable
=#
"""Union type for `Float64` and `Nothing`."""
const FON = Union{Nothing,Float64}

"""A 3 long vector of `nothing`s."""
const NOTHING3 = [nothing, nothing, nothing]

"""Create a homogeneous vector by appending 1 to the end of a vector."""
HV(v) = vcat(v, 1)

include("partzeros.jl")
include("geometries.jl")
include("tolerances.jl")
#include("optimizationproblem.jl")
#include("optimization.jl")
#include("resultevaluation.jl")

end
