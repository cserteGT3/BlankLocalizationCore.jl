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

"""
    visualizationgeometry(geom::AbstractLocalizationGeometry)

Return a Meshes.jl object that can be visualized.
"""
function visualizationgeometry end

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

function visualizationgeometry(hole::SimpleHole)
    # p1: feature point
    p1 = Point3(hole.p)
    # p2: deeper in the hole
    p2 = p1 - Vec3(0,0,0.01)
    ax = Vec3(0,0,1)
    bottom = Plane(p2, ax)
    top = Plane(p1, ax)
    return Cylinder(bottom, top, hole.r)
end

"""
SimplePlane <: AbstractPlaneGeometry

A simple plane structure with one point.
Normal vector of the plane is defined by its partzero taken from the feature descriptor.
"""
struct SimplePlane <: AbstractPlaneGeometry
    p::Vector{Float64}
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
    return rectangleforplane(plane.p, [1,0,0], [0,1,0], 20)
end

"""
PlaneAndNormal <: AbstractPlaneGeometry

A simple plane structure with one point and a normal vector.
"""
struct PlaneAndNormal <: AbstractPlaneGeometry
    p::Vector{Float64}
    n::Vector{Float64}
end

GeometryStyle(::Type{PlaneAndNormal}) = IsPrimitive()

# should try first the 3 axes
randnormal(v::Vector) = normalize(cross(v, rand(3)))

function visualizationgeometry(plane::PlaneAndNormal)
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

function visualizationgeometry(meshplane::MeshPlane)
    return meshplane.surface
end

function filteredsurfacepoints(::IsFreeForm, x::MeshPlane)
    bbox = boundingbox(x.surface)
    return [bbox.min.coords, bbox.max.coords]
end


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

emptyor() = OptimizationResult("empty", 0.0)

struct Tolerance
    featurename1::String
    ismachined1::Bool
    projection::Function
    featurename2::String
    ismachined2::Bool
    nominalvalue::Float64
    lowervalue::Float64
    uppervalue::Float64
    note::String
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
    holetypes = GeometryStyle.(typeof.(x.rough for x in mop.holes))
    for ht in holetypes
        ht === IsFreeForm() && return :HybridProblem
    end
    planetypes = GeometryStyle.(typeof.(x.rough for x in mop.planes))
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

"""
    setparameters!(mop::MultiOperationProblem, pardict)

Set parameter dictionary of a `MultiOperationProblem` to `pardict`.
"""
function setparameters!(mop::MultiOperationProblem, pardict)
    mop.parameters = pardict
    return mop
end

"""
    getfeaturebyname(mop::MultiOperationProblem, featurename)

Get a hole or plane feature by its name.
It is assumed that all features have distinct names.
Return `nothing`, if no feature is found with `featurename`.
"""
function getfeaturebyname(mop::MultiOperationProblem, featurename)
    function retbyname(array, name)
        for f in array
            if getfeaturename(f) == name
                return f
            end
        end
        return nothing
    end

    hole_ = retbyname(mop.holes, featurename)
    isnothing(hole_) || return hole_
    # return plane even if it is nothing
    return retbyname(mop.planes, featurename)
end

"""
    collectholesbypartzero(mop::MultiOperationProblem, partzeroname)

Collect holes that are grouped to part zero called `partzeroname`.
"""
function getholesbypartzero(mop::MultiOperationProblem, partzeroname)
    return filter(x->getpartzeroname(x) == partzeroname, mop.holes)
end

"""
    collectmachinedholes(mop::MultiOperationProblem)

Collect holes that have a machined state.
"""
collectmachinedholes(mop::MultiOperationProblem) = filter(hasmachined, mop.holes)

"""
    collectmachinedplanes(mop::MultiOperationProblem)

Collect planes that have a machined state.
"""
collectmachinedplanes(mop::MultiOperationProblem) = filter(hasmachined, mop.planes)

"""
    collectroughholes(mop::MultiOperationProblem)

Collect those holes, that have rough stage.
"""
collectroughholes(mop::MultiOperationProblem) = filter(hasrough, mop.holes)

"""
    collectroughplanes(mop::MultiOperationProblem)

Collect those planes, that have rough stage.
"""
collectroughplanes(mop::MultiOperationProblem) = filter(hasrough, mop.planes)
