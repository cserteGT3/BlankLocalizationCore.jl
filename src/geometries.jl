"""Supertype for localization geometries."""
abstract type AbstractLocalizationGeometry end

"""Supertype of hole like localization geometries."""
abstract type AbstractHoleGeometry <: AbstractLocalizationGeometry end

"""Supertype of plane like geometries."""
abstract type AbstractPlaneGeometry <: AbstractLocalizationGeometry end


# Traits that all features need to have:
# rough OR machined -> this can be eliminated by having two fields: rough and machined
# primitive OR freeform
# hole OR plane: trait/abstract type/type parameter???


"""Trait that describes the "style" of an [`AbstractLocalizationGeometry`](@ref)."""
abstract type GeometryStyle end

"""Primitive geometries can be explicitly described, e.g. a box or sphere."""
struct IsPrimitive <: GeometryStyle end
"""Free form geometries are discrete representations, e.g. a mesh or a point cloud."""
struct IsFreeForm <: GeometryStyle end

# don't define a global default (currently it helps development and debugging)
#GeometryStyle(::Type) = IsPrimitive()

# Functions to be implemented to comply with the interface:
# radius(HoleGeometry) - return the radius of a hole feature
# primitive features have feature points
featurepoint(x::T) where {T} = featurepoint(GeometryStyle(T), x)
featurepoint(::IsPrimitive, x) = x.p
function featurepoint(::IsFreeForm, x)
    error("featurepoint function is not defined for `IsFreeForm`` features")
end

"""
SimpleHole <: AbstractHoleGeometry

A simple "hole" structure with a center point and a radius.
Axis of the hole is defined by its partzero taken from the feature descriptor.
"""
struct SimpleHole <: AbstractHoleGeometry
    p::Vector{Float64}
    r::Float64
end

GeometryStyle(::Type{SimpleHole}) = IsPrimitive()

"""
SimplePlane <: AbstractPlaneGeometry

A simple plane structure with one point.
Normal vector of the plane is defined by its partzero taken from the feature descriptor.
"""
struct SimplePlane <: AbstractPlaneGeometry
    p::Vector{Float64}
end

GeometryStyle(::Type{SimplePlane}) = IsPrimitive()

"""
MeshHole <: AbstractHoleGeometry

A simple mesh hole geometry, that contains the mesh of the hole's surface and the convex
hull of the points (see our paper for details).
"""
struct MeshHole <: AbstractHoleGeometry
    mesh
    chull
end

GeometryStyle(::Type{MeshHole}) = IsFreeForm()

"""
MeshPlane <: AbstractPlaneGeometry

A simple mesh plane geometry, that contains the mesh of a planar face.
"""
struct MeshPlane <: AbstractPlaneGeometry
    mesh
end

GeometryStyle(::Type{MeshPlane}) = IsFreeForm()

"""
Store description of a feature: its name, the corresponding part zero, if it has or has not
a machined and a rough state.
"""
struct FeatureDescriptor
    name::String
    partzero::PartZero
    hasmachined::Bool
    hasrough::Bool
end

function Base.show(io::IO, fd::FeatureDescriptor)
    print(io, fd.name, " in ", fd.partzero.name,
    fd.hasmachined ? "; machined, " : "; ! machined, ",
    fd.hasrough ? "rough" : "! rough")
end

"""
    LocalizationFeature{R,M}

Supertype of any localization features.
A localization feature contains a feature
descriptor ([`FeatureDescriptor`](@ref)) and a rough and machined geometry
([`AbstractLocalizationGeometry`](@ref)).
The two geometries must be of same type (hole, plane, etc.).
If a feature doesn't have a rough of machined state, an empty object should be used
(and the feature descriptor should also store this information).
A `LocalizationFeature` must define if it is [`IsPrimitive`](@ref) or [`IsFreeForm`](@ref)
based on its rough geometry.
"""
abstract type LocalizationFeature{R,M} end

# I thought this should cover all subtypes, but it doesn't. But I don't know why
#GeometryStyle(::Type{LocalizationFeature{R,M}}) where {R,M} = GeometryStyle(R)

function Base.show(io::IO, lf::LocalizationFeature)
    print(io, typeof(lf), ": ", lf.descriptor.name)
end

struct HoleLocalizationFeature{R<:AbstractHoleGeometry,M<:AbstractHoleGeometry} <: LocalizationFeature{R,M}
    descriptor::FeatureDescriptor
    rough::R
    machined::M
end

GeometryStyle(::Type{HoleLocalizationFeature{R,M}}) where {R,M} = GeometryStyle(R)

struct PlaneLocalizationFeature{R<:AbstractPlaneGeometry,M<:AbstractPlaneGeometry} <: LocalizationFeature{R,M}
    descriptor::FeatureDescriptor
    rough::R
    machined::M
end

GeometryStyle(::Type{PlaneLocalizationFeature{R,M}}) where {R,M} = GeometryStyle(R)

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

emptyor() = OptimizationResult("not yet run", 0.0)

struct Tolerance
    featurename1::String
    machinedorrough1::String
    projection::Function
    featurename2::String
    machinedorrough2::String
    nominalvalue::Float64
    lowervalue::Float64
    uppervalue::Float64
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
    holetypes = GeometryStyle.(typeof.(mop.holes))
    for ht in holetypes
        ht === IsFreeForm() && return :HybridProblem
    end
    planetypes = GeometryStyle.(typeof.(mop.planes))
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
