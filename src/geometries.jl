"""
    RepresentationStyle

Trait that describes the "style" of an [`AbstractLocalizationGeometry`](@ref).
If it can be described by a primitive, then it is [`Primitive`](@ref) and
[`FreeForm`](@ref) otherwise.
"""
abstract type RepresentationStyle end

"""Primitive geometries can be explicitly described, e.g. a box or sphere."""
struct Primitive <: RepresentationStyle end

"""Free form geometries are discrete representations, e.g. a mesh or a point cloud."""
struct FreeForm <: RepresentationStyle end

nicestr(x::Primitive) = "primitive"
nicestr(x::FreeForm) = "free form"

abstract type FeatureStyle end
struct Planar <: FeatureStyle end
struct Cylindrical <: FeatureStyle end

nicestr(x::Planar) = "planar"
nicestr(x::Cylindrical) = "cylindrical"

abstract type AbstractLocalizationGeometry end

struct SimpleHole <: AbstractLocalizationGeometry
    geom::Meshes.Disk
end

RepresentationStyle(g::SimpleHole) = Primitive()
FeatureStyle(g::SimpleHole) = Cylindrical()

featurepoint(g::SimpleHole) = Meshes.plane(g.geom)(0,0)
featureradius(g::SimpleHole) = radius(g.geom)

struct MeshHole <: AbstractLocalizationGeometry
    geom #::Meshes.Mesh, but that is abstract
    chull # vector of points / vector of vectors - TBD
end

RepresentationStyle(g::MeshHole) = FreeForm()
FeatureStyle(g::MeshHole) = Cylindrical()

surfacepoints(g::MeshHole) = vertices(g.geom)
filteredsurfacepoints(g::MeshHole) = g.chull

struct SimplePlane <: AbstractLocalizationGeometry
    geom::Meshes.Plane
end

RepresentationStyle(g::SimplePlane) = Primitive()
FeatureStyle(g::SimplePlane) = Planar()

featurepoint(g::SimplePlane) = g.geom(0,0)

struct MeshPlane <: AbstractLocalizationGeometry
    geom #::Meshes.Mesh, but that is abstract
end

RepresentationStyle(g::MeshPlane) = FreeForm()
FeatureStyle(g::MeshPlane) = Planar()

surfacepoints(g::MeshPlane) = vertices(g.geom)
filteredsurfacepoints(g::MeshPlane) = vertices(g.geom)




"""Supertype for feature types."""
abstract type AbstractFeature end

RepresentationStyle(f::AbstractFeature) = RepresentationStyle(f.geometry)
FeatureStyle(f::AbstractFeature) = FeatureStyle(f.geometry)
featurename(f::AbstractFeature) = f.name
geometry(f::AbstractFeature) = f.geometry

isplanar(st::AbstractFeature) = FeatureStyle(st) === Planar()
iscylindrical(st::AbstractFeature) = FeatureStyle(st) === Cylindrical()

"""
    featurepoint(f::AbstractFeature)

Return the feature point of an [`Primitive`](@ref) geometry.
"""
featurepoint(f::AbstractFeature) = featurepoint(RepresentationStyle(f), f)
featurepoint(::Primitive, f) = featurepoint(geometry(f))
function featurepoint(::FreeForm, f)
    error("Function `featurepoint` is not defined for `FreeForm` features.")
end

"""
    surfacepoints(f::AbstractFeature)

Return the points of the surface of an [`FreeForm`](@ref) geometry.
"""
surfacepoints(f::AbstractFeature) = surfacepoints(RepresentationStyle(f), f)

surfacepoints(::FreeForm, f) = surfacepoints(geometry(f))

function surfacepoints(::Primitive, f)
    error("Function `surfacepoints` is not defined for `Primitive` features.")
end

"""
    featureradius(f::AbstractFeature)

Return the radius of a [`Primitive`](@ref) geometry, that is `Cylindrical`.
"""
featureradius(f::AbstractFeature) = featureradius(RepresentationStyle(f), FeatureStyle(f), f)

featureradius(::Primitive, ::Cylindrical, f) = featureradius(geometry(f))

function featureradius(t1, t2, f)
    error("Function `featureradius` is only defined for ::Primitive and ::Cylindrical features. Got $t1 and $t2")
end

struct RoughFeature <: AbstractFeature
    name::String
    geometry # <: AbstractLocalizationGeometry
end

struct MachinedFeature <: AbstractFeature
    name::String
    geometry # <: AbstractLocalizationGeometry
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
struct LocalizationFeature
    name::String
    roughfeature::RoughFeature
    machinedfeature::MachinedFeature
    function LocalizationFeature(n, r, m)
        if FeatureStyle(r) === FeatureStyle(m)
            new(n, r, m)
        else
            error("FeatureStyle of rough and machined features does not match!")
        end
    end
end

featurename(lf::LocalizationFeature) = lf.name
partzero(lf::LocalizationFeature) = partzero(lf.machinedfeature)
partzeroname(lf::LocalizationFeature) = partzeroname(partzero(lf))
isplanar(lf::LocalizationFeature) = isplanar(lf.roughfeature)
iscylindrical(lf::LocalizationFeature) = iscylindrical(lf.roughfeature)
RepresentationStyle(lf::LocalizationFeature) = RepresentationStyle(lf.roughfeature)
FeatureStyle(lf::LocalizationFeature) = FeatureStyle(lf.roughfeature)

function Base.show(io::IO, lf::LocalizationFeature)
    print(io, "LocalizationFeature: ", featurename(lf),
    " ", nicestr(RepresentationStyle(lf)), ", ", nicestr(FeatureStyle(lf)))
end

roughfeaturepoint(lf::LocalizationFeature) = featurepoint(lf.roughfeature)
machinedfeaturepoint(lf::LocalizationFeature) = featurepoint(lf.machinedfeature)
roughradius(lf::LocalizationFeature) = featureradius(lf.roughfeature)
machinedradius(lf::LocalizationFeature) = featureradius(lf.machinedfeature)
machinedfilteredsurfacepoints(lf::LocalizationFeature) = filteredsurfacepoints(lf.machinedfeature)
roughfilteredsurfacepoints(lf::LocalizationFeature) = filteredsurfacepoints(lf.roughfeature)

#=
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
=#

