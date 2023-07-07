"""Supertype of localization geometries."""
abstract type AbstractLocalizationGeometry end

"""Supertype of hole like localization geometries."""
abstract type AbstractHoleGeometry <: AbstractLocalizationGeometry end

"""Supertype of plane like geometries."""
abstract type AbstractPlaneGeometry <: AbstractLocalizationGeometry end

"""
Trait that describes the "style" of an [`AbstractLocalizationGeometry`](@ref).
If it can be described by a primitive, then it is [`IsPrimitive`](@ref) and
[`IsFreeForm`](@ref) otherwise.
"""
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
    LocalizationFeature{R,M}

A feature that is machined and allowance can be computed for it.
It has a name, a [`PartZero`](@ref), and a rough and machined geometry
([`AbstractLocalizationGeometry`](@ref)).
The two geometries should be of same type (hole, plane, etc.),
but [`HoleLocalizationFeature`](@ref) and [`PlaneLocalizationFeature`](@ref) enforce this
property
"""
struct LocalizationFeature{R,M}
    name::String
    partzero::PartZero
    rough::R
    machined::M
end

const HoleLocalizationFeature{R,M} = LocalizationFeature{R,M} where {R<:AbstractHoleGeometry, M<:AbstractHoleGeometry}

HoleLocalizationFeature(n, p, r, m) = LocalizationFeature(n, p, r, m)

const PlaneLocalizationFeature{R,M} = LocalizationFeature{R,M} where {R<:AbstractPlaneGeometry, M<:AbstractPlaneGeometry}

PlaneLocalizationFeature(n, p, r, m) = LocalizationFeature(n, p, r, m)

GeometryStyle(::Type{LocalizationFeature{R,M}}) where {R,M} = GeometryStyle(R)

function Base.show(io::IO, lf::LocalizationFeature)
    print(io, typeof(lf), ": ", getfeaturename(lf))
end

getfeaturename(f::LocalizationFeature) = f.name
getpartzero(f::LocalizationFeature) = getpartzero(f.partzero)
getpartzeroname(f::LocalizationFeature) = getpartzeroname(f.partzero)

getroughfeaturepoint(f::LocalizationFeature) = featurepoint(f.rough)
getmachinedfeaturepoint(f::LocalizationFeature) = featurepoint(f.machined)
getmachinedradius(f::LocalizationFeature) = featureradius(f.machined)
getroughradius(f::LocalizationFeature) = featureradius(f.rough)

getroughfilteredpoints(f::LocalizationFeature) = filteredsurfacepoints(f.rough)

function getmachinedfeaturepointindatum(f::LocalizationFeature)
    v = getmachinedfeaturepoint(f)
    pz = getpartzero(f)
    T = getpartzeroHM(pz)
    v_indatum = T*HV(v)
    return v_indatum[1:3]
end
