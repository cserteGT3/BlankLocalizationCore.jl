"""Supertype of localization geometries."""
abstract type AbstractLocalizationGeometry end

"""Supertype of hole like localization geometries."""
abstract type AbstractHoleGeometry <: AbstractLocalizationGeometry end

"""Supertype of plane like geometries."""
abstract type AbstractPlaneGeometry <: AbstractLocalizationGeometry end

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

# don't define a global default (currently it helps development and debugging)
#GeometryStyle(::Type) = IsPrimitive()

"""
    visualizationgeometry(geom::AbstractLocalizationGeometry)

Return a Meshes.jl object that can be visualized.
"""
function visualizationgeometry end

"""
    featurepoint()

Return the feature point of an [`IsPrimitive`](@ref) geometry.
Definition signature should look like: `featurepoint(::IsPrimitive, x)`.
"""
function featurepoint end

"""
    surfacepoints()

Return the points of the surface of an [`IsFreeForm`](@ref) geometry.
Definition signature should look like: `surfacepoints(::IsFreeForm, x)`.
"""
function surfacepoints end

"""
    filteredsurfacepoints()

Return the filtered points of the surface of an [`IsFreeForm`](@ref) geometry, 
that may define active constraints in the optimization task
(for example convex hull of mesh).
Definition signature should look like: `filteredsurfacepoints(::IsFreeForm, x)`.
"""
function filteredsurfacepoints end

"""
    featureradius()

Return the radius of a [`IsPrimitive`](@ref) geometry
that is subtype of [`AbstractHoleGeometry`].
There is a default implementation that can be used: `featureradius(::IsPrimitive, x) = x.r`.
"""
function featureradius end

featurepoint(x::T) where {T} = featurepoint(GeometryStyle(T), x)
featurepoint(::IsPrimitive, x) = x.p
function featurepoint(::IsFreeForm, x)
    error("Function `featurepoint` is not defined for `IsFreeForm`` features")
end


surfacepoints(x::T) where {T} = surfacepoints(GeometryStyle(T), x)
function surfacepoints(::IsPrimitive, x)
    error("Function `surfacepoints` is not defined for `IsPrimitive`` features")
end


filteredsurfacepoints(x::T) where {T} = filteredsurfacepoints(GeometryStyle(T), x)
function filteredsurfacepoints(::IsPrimitive, x)
    error("Function `filteredsurfacepoints` is not defined for `IsPrimitive`` features")
end

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

function visualizationgeometry(hole::SimpleHole)
    # p1: feature point
    p1 = Point3(hole.p)
    return Disk(Plane(p1, Vec3(0,0,1)), hole.r)
end

"""
SimplePlane <: AbstractPlaneGeometry

A simple plane structure with one point and a normal vector.
"""
struct SimplePlane <: AbstractPlaneGeometry
    p::Vector{Float64}
    n::Vector{Float64}
end

GeometryStyle(::Type{SimplePlane}) = IsPrimitive()

function rectangleforplane(point, v1 ,v2, sidelength)
    c1 = point + sidelength/2*v1 + -1*sidelength/2*v2
    c2 = c1 + -1*sidelength*v1
    c3 = c2 + sidelength*v2
    c4 = c3 + sidelength*v1
    g1 = Point3(c1)
    g2 = Point3(c2)
    g3 = Point3(c3)
    g4 = Point3(c4)
    return SimpleMesh([g1,g2,g3,g4], connect.([(1,2,3),(3,4,1)]))
end

function visualizationgeometry(plane::SimplePlane)
    o = plane.p
    v1 = randnormal(plane.n)
    v2 = cross(v1, plane.n)
    return rectangleforplane(o, v1, v2, 20)
end

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

function surfacepoints(::IsFreeForm, x::MeshHole)
    points = vertices(x.surface)
    verts = [x.coords for x in points]
    return verts
end

function visualizationgeometry(meshhole::MeshHole)
    return meshhole.surface
end

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

GeometryStyle(::Type{MeshPlane}) = IsFreeForm()

function surfacepoints(::IsFreeForm, x::MeshPlane)
    points = vertices(x.surface)
    verts = [x.coords for x in points]
    return verts
end

function visualizationgeometry(meshplane::MeshPlane)
    return meshplane.surface
end

function filteredsurfacepoints(::IsFreeForm, x::MeshPlane)
    bbox = boundingbox(x.surface)
    return [bbox.min.coords, bbox.max.coords]
end


"""
    LocalizationFeature{R,M}

A feature that is machined and allowance can be computed for it.
It has a name, a [`PartZero`](@ref), and a rough and machined geometry
([`AbstractLocalizationGeometry`](@ref)).
The two geometries should be of same type (hole, plane, etc.), but only
[`HoleLocalizationFeature`](@ref) and [`PlaneLocalizationFeature`](@ref) enforce this property.
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
getpartzero(f::LocalizationFeature) = f.partzero
getpartzeroname(f::LocalizationFeature) = getpartzeroname(f.partzero)

getroughfeaturepoint(f::LocalizationFeature) = featurepoint(f.rough)
getmachinedfeaturepoint(f::LocalizationFeature) = featurepoint(f.machined)
getroughradius(f::LocalizationFeature) = featureradius(f.rough)
getmachinedradius(f::LocalizationFeature) = featureradius(f.machined)

getroughfilteredpoints(f::LocalizationFeature) = filteredsurfacepoints(f.rough)

function getmachinedfeaturepointindatum(f::LocalizationFeature)
    v = getmachinedfeaturepoint(f)
    pz = getpartzero(f)
    T = getpartzeroHM(pz)
    v_indatum = T*HV(v)
    return v_indatum[1:3]
end

"""
    transformmachined2datum(feature, points)

Transform a list of points with the part zero of `feature`.
"""
function transformmachined2datum(feature, points)
    pz = getpartzero(feature)
    M = getpartzeroHM(pz)
    newpoints = (M*HV(p) for p in points)
    resultpoints = [p[1:3] for p in newpoints]
    return resultpoints
end
