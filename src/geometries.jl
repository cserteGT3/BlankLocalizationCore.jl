"""
    GeometryStyle

Trait that describes the "style" of an [`AbstractLocalizationGeometry`](@ref).
If it can be described by a primitive, then it is [`IsPrimitive`](@ref) and
[`IsFreeForm`](@ref) otherwise.
"""
abstract type GeometryStyle end

"""Primitive geometries can be explicitly described, e.g. a box or sphere."""
struct IsPrimitive <: GeometryStyle end

"""Free form geometries are discrete representations, e.g. a mesh or a point cloud."""
struct IsFreeForm <: GeometryStyle end

"""Enum to store if a feature is hole or plane like."""
@enum GeometryType PLANELIKE HOLELIKE

"""Supertype for feature types."""
abstract type AbstractFeature{G} end

GeometryStyle(f::AbstractFeature) = GeometryStyle(f.geometry)
featurename(f::AbstractFeature) = f.name
geometrytype(f::AbstractFeature) = f.gtype
geometry(f::AbstractFeature) = f.geometry

isplanelike(st::AbstractFeature) = geometrytype(st) == PLANELIKE
isholelike(st::AbstractFeature) = geometrytype(st) == HOLELIKE

"""
    featurepoint(f::AbstractFeature)

Return the feature point of an [`IsPrimitive`](@ref) geometry.
"""
featurepoint(f::AbstractFeature) = featurepoint(GeometryStyle(f), f)
featurepoint(::IsPrimitive, f) = featurepoint(geometry(f))
function featurepoint(::IsFreeForm, f)
    error("Function `featurepoint` is not defined for `IsFreeForm` features.")
end

"""
    surfacepoints(f::AbstractFeature)

Return the points of the surface of an [`IsFreeForm`](@ref) geometry.
"""
surfacepoints(f::AbstractFeature) = surfacepoints(GeometryStyle(f), f)

surfacepoints(::IsFreeForm, f) = surfacepoints(geometry(f))

function surfacepoints(::IsPrimitive, f)
    error("Function `surfacepoints` is not defined for `IsPrimitive` features.")
end

"""
    featureradius(f::AbstractFeature)

Return the radius of a [`IsPrimitive`](@ref) geometry, that is `HOLELIKE`.
"""
featureradius(f::AbstractFeature) = featureradius(GeometryStyle(f), f)

function featureradius(::IsPrimitive, f)
    if isholelike(f)
        return featureradius(geometry(f))
    else
        error("Function `featureradius` is only defined for `HOLELIKE` features.")
    end
end

function featureradius(::IsFreeForm, f)
    error("Function `featureradius` is not defined for `IsFreeForm` features.")
end

## default functions for Cylinders, Planes and Meshes
featurepoint(g::Meshes.Plane) = g(0,0)

featurepoint(g::Meshes.Cylinder) = featurepoint(top(g))

surfacepoints(g::Meshes.Mesh) = vertices(g)

featureradius(g::Meshes.Cylinder) = radius(g)

struct RoughFeature{G} <: AbstractFeature{G}
    name::String
    gtype::GeometryType
    geometry::G
end

GeometryStyle(f::Meshes.Primitive) = IsPrimitive()
GeometryStyle(f::Meshes.Domain) = IsFreeForm()
#GeometryStyle(f) = IsFreeForm()

#=
for ST = subtypes(Meshes.Primitive)
    eval(quote
        GeometryStyle(::Type{$ST}) = IsPrimitive()    
    end)
end
GeometryStyle(::Type) = IsFreeForm()
=#

struct MachinedFeature{G<:Meshes.Primitive} <: AbstractFeature{G}
    name::String
    gtype::GeometryType
    geometry::G
    partzero::PartZero
end

partzero(f::MachinedFeature) = f.partzero
partzeroname(f::MachinedFeature) = partzeroname(f.partzero)


"""
    LocalizationFeature

A feature that is machined and allowance can be computed for it.
It has a name, a [`RoughFeature`](@ref) and a [`MachinedFeature`](@ref).
The two geometries should be of same [`GeometryType`](@ref) (holelike or planelike),
the constructor enforces this property.
"""
struct LocalizationFeature{G}
    name::String
    roughfeature::RoughFeature{G}
    machinedfeature::MachinedFeature
    function LocalizationFeature(n, r::RoughFeature{T}, m) where {T}
        if isplanelike(r) == isplanelike(m)
            new{T}(n, r, m)
        else
            error("GeometryType of rough and machined does not match!")
        end
    end
end

featurename(lf::LocalizationFeature) = lf.name
partzero(lf::LocalizationFeature) = partzero(lf.machinedfeature)
partzeroname(lf::LocalizationFeature) = partzeroname(lf.partzero)
isplanelike(lf::LocalizationFeature) = isplanelike(lf.roughfeature)
isholelike(lf::LocalizationFeature) = isholelike(lf.roughfeature)
GeometryStyle(lf::LocalizationFeature) = GeometryStyle(lf.roughfeature)

function Base.show(io::IO, lf::LocalizationFeature)
    print(io, typeof(lf), ": ", featurename(lf))
end

roughfeaturepoint(lf::LocalizationFeature) = featurepoint(lf.rough)
machinedfeaturepoint(lf::LocalizationFeature) = featurepoint(lf.machined)
roughradius(lf::LocalizationFeature) = featureradius(lf.rough)
machinedradius(lf::LocalizationFeature) = featureradius(lf.machined)

function machinedfeaturepointindatum(f::LocalizationFeature)
    v = machinedfeaturepoint(f)
    pz = partzero(f)
    T = getpartzeroHM(pz)
    v_indatum = T*HV(v)
    return v_indatum[1:3]
end

"""
    transformmachined2datum(feature, points)

Transform a list of points with the part zero of `feature`.
"""
function transformmachined2datum(feature, points)
    pz = partzero(feature)
    M = getpartzeroHM(pz)
    newpoints = (M*HV(p) for p in points)
    resultpoints = [p[1:3] for p in newpoints]
    return resultpoints
end
