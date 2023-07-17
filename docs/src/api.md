# Using the API to extend the geometry types

The solver handles hole and face (plane) features that are either [`IsPrimitive`](@ref) or [`IsFreeForm`](@ref).
A few basic types are defined like [`SimpleHole`](@ref) and [`MeshHole`](@ref), but new ones can be also defined.
For example for point clouds, that don't have faces, like a mesh, only points.

This capability is properly documented, as a major API rewrite is going on in [#3](https://github.com/cserteGT3/BlankLocalizationCore.jl/pull/3).

## Defining a new geometry

Defining a new geometry is pretty easy:

* It has to be the subtype of either [`AbstractHoleGeometry`](@ref) or [`AbstractPlaneGeometry`](@ref).
* The [`GeometryStyle`](@ref) trait is need to be defined: it is either a [`IsPrimitive`](@ref) or [`IsFreeForm`](@ref) geometry.
* `IsFreeForm` geometries need to define the [`surfacepoints`](@ref) and [`filteredsurfacepoints`](@ref) functions.
* `IsPrimitive` geometries need to define the [`featurepoint`](@ref) functions
* Those `IsPrimitive` geometries that are subtype of `AbstractHoleGeometry` also need to define the [`featureradius`](@ref) function
* Finally, for visualization purposes the [`visualizationgeometry`](@ref) function should be defined, that returns an object, that can be used with the `Meshviz.viz()` function.

## An example

Let's assume that we want to define a new holelike type: `MyDisk`, which has a featurepoint, a normal, and a radius.

```julia
using BlankLocalizationCore

struct MyDisk <: AbstractHoleGeometry
    point::Vector{Float64}
    normal::Vector{Float64}
    diameter::Float64
end

GeometryStyle(::Type{MyDisk}) = IsPrimitive()
```

It is an `IsPrimitive` and holelike feature, therefore we need to define the:

* `featurepoint`
* `featureradius`
* `visualizationgeometry`

functions.
These look like as follows:

```julia
featurepoint(::IsPrimitive, x::MyDisk) = x.point
featureradius(::IsPrimitive, x::MyDisk) = x.diameter/2

using Meshes

function visualizationgeometry(geom::MyDisk)
    plane = Plane(Point3(geom.point), Vec3(geom.normal))
    return Disk(plane, geom.diameter/2)
end

```
