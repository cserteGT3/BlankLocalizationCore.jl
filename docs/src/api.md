# Using the API to extend the geometry types

The solver handles hole and face (plane) features that are either [`IsPrimitive`](@ref) or [`IsFreeForm`](@ref).
A few basic types are defined like [`SimpleHole`](@ref) and [`MeshHole`](@ref), but new ones can be also defined.
For example for point clouds, that don't have faces, like a mesh, only points.

This capability is not yet documented, as a major API rewrite is going on in [#3](https://github.com/cserteGT3/BlankLocalizationCore.jl/pull/3).
