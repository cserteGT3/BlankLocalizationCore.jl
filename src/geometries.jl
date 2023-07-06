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
# primitive features have feature points
featurepoint(x::T) where {T} = featurepoint(GeometryStyle(T), x)
featurepoint(::IsPrimitive, x) = x.p
function featurepoint(::IsFreeForm, x)
    error("Function `featurepoint` is not defined for `IsFreeForm`` features")
end

# Functions to be implemented to comply with the interface:
# free form geometries have surfacepoints
# return all points of a free form surface
surfacepoints(x::T) where {T} = surfacepoints(GeometryStyle(T), x)
#surfacepoints(::IsFreeForm, x) = x.p
function surfacepoints(::IsPrimitive, x)
    error("Function `surfacepoints` is not defined for `IsFreeForm`` features")
end

# free form geometries have surfacepoints
# return only those points, that may define active constraints
filteredsurfacepoints(x::T) where {T} = filteredsurfacepoints(GeometryStyle(T), x)
function filteredsurfacepoints(::IsPrimitive, x)
    error("Function `surfacepoints` is not defined for `IsPrimitive`` features")
end

# radius is only defined for hole like features that are IsPrimitive
featureradius(x::T) where {T<:AbstractHoleGeometry} = featureradius(GeometryStyle(T), x)
featureradius(::IsPrimitive, x) = x.r
function featureradius(::IsFreeForm, x)
    error("Function `featureradius` is not defined for `IsFreeForm`` features")
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
    surface::SimpleMesh
    convexhull::Vector{Vector{Float64}}
end

GeometryStyle(::Type{MeshHole}) = IsFreeForm()

function filteredsurfacepoints(::IsFreeForm, x::MeshHole)
    return x.convexhull
end

"""
MeshPlane <: AbstractPlaneGeometry

A simple mesh plane geometry, that contains the mesh of a planar face.
"""
struct MeshPlane <: AbstractPlaneGeometry
    surface::SimpleMesh
end

function filteredsurfacepoints(::IsFreeForm, x::MeshPlane)
    bbox = boundingbox(x.surface)
    return [bbox.min.coords, bbox.max.coords]
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

getfeaturename(f::FeatureDescriptor) = f.name
getpartzero(f::FeatureDescriptor) = f.partzero
getpartzeroname(f::FeatureDescriptor) = getpartzeroname(getpartzero(f))
hasmachined(f::FeatureDescriptor) = f.hasmachined
hasrough(f::FeatureDescriptor) = f.hasrough

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

#GeometryStyle(::Type{HoleLocalizationFeature{R,M}}) where {R,M} = GeometryStyle(R)

struct PlaneLocalizationFeature{R<:AbstractPlaneGeometry,M<:AbstractPlaneGeometry} <: LocalizationFeature{R,M}
    descriptor::FeatureDescriptor
    rough::R
    machined::M
end

#GeometryStyle(::Type{PlaneLocalizationFeature{R,M}}) where {R,M} = GeometryStyle(R)

getfeaturename(f::LocalizationFeature) = getfeaturename(f.descriptor)
getpartzero(f::LocalizationFeature) = getpartzero(f.descriptor)
getpartzeroname(f::LocalizationFeature) = getpartzeroname(f.descriptor)
hasmachined(f::LocalizationFeature) = hasmachined(f.descriptor)
hasrough(f::LocalizationFeature) = hasrough(f.descriptor)

getroughfeaturepoint(f::LocalizationFeature) = featurepoint(f.rough)
getmachinedfeaturepoint(f::LocalizationFeature) = featurepoint(f.machined)
getmachinedradius(f::LocalizationFeature) = featureradius(f.machined)
getroughradius(f::LocalizationFeature) = featureradius(f.rough)

getroughfilteredpoints(f::LocalizationFeature) = filteredsurfacepoints(f.rough)

function getmachinedfeaturepointindatum(f::LocalizationFeature)
    @assert hasmachined(f)
    v = getmachinedfeaturepoint(f)
    pz = getpartzero(f)
    T = getpartzeroHM(pz)
    v_indatum = T*HV(v)
    return v_indatum[1:3]
end
