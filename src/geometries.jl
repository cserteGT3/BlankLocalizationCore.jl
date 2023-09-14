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


"""
    GeometryStyle

Trait that describes the "style" of an [`AbstractLocalizationGeometry`](@ref).
Currently it can be either [`IsPrimitive`](@ref) or [`IsFreeForm`](@ref).
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
    error("Function `surfacepoints` is not defined for `IsFreeForm`` features")
end


filteredsurfacepoints(x::T) where {T} = filteredsurfacepoints(GeometryStyle(T), x)
function filteredsurfacepoints(::IsPrimitive, x)
    error("Function `surfacepoints` is not defined for `IsPrimitive`` features")
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
based on its rough geometry.
"""
abstract type LocalizationFeature{R,M} end

function Base.show(io::IO, lf::LocalizationFeature)
    print(io, typeof(lf), ": ", lf.descriptor.name)
end

"""
    HoleLocalizationFeature(descriptor::FeatureDescriptor, rough::R, machined::M) where {R<:AbstractHoleGeometry,M<:AbstractHoleGeometry}

A holelike localization feature. The rough and machined geometries don't necessarily
have to be the same type.
"""
struct HoleLocalizationFeature{R<:AbstractHoleGeometry,M<:AbstractHoleGeometry} <: LocalizationFeature{R,M}
    descriptor::FeatureDescriptor
    rough::R
    machined::M
end

"""
    PlaneLocalizationFeature(descriptor::FeatureDescriptor, rough::R, machined::M) where {R<:AbstractPlaneGeometry,M<:AbstractPlaneGeometry}

A planelike localization feature. The rough and machined geometries don't necessarily
have to be the same type.
"""
struct PlaneLocalizationFeature{R<:AbstractPlaneGeometry,M<:AbstractPlaneGeometry} <: LocalizationFeature{R,M}
    descriptor::FeatureDescriptor
    rough::R
    machined::M
end

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

"""
    MultiOperationProblem

Collect all data for a multi operation problem, including: part zeros, holes, planes,
tolerances, parameters and optimization result.
"""
mutable struct MultiOperationProblem
    partzeros::Vector{PartZero}
    holes::Vector{HoleLocalizationFeature}
    planes::Vector{PlaneLocalizationFeature}
    tolerances::Vector{Tolerance}
    parameters::Dict{String,Any}
    opresult::OptimizationResult
end

"""
    MultiOperationProblem(partzeros, holes, planes, tolerances, parameters)

Construct a multi operation problem.
For usage, please see the example section in the documentation.
The parameters for the optimization are also described there with greater details.

# Arguments

- `partzeros::Vector{PartZero}`: array of part zeros.
- `holes::Vector{HoleLocalizationFeature}`: array of holes.
- `planes::Vector{PlaneLocalizationFeature}`: array of planes.
- `tolerances::Vector{Tolerance}`: array of tolerances.
- `parameters::Dict{String,Any}`: parameters in the form of a dictionary. Keys include:
    `minAllowance`, `OptimizeForToleranceCenter`, `UseTolerances`,
    `SetPartZeroPosition`, `maxPlaneZAllowance`.
"""
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
