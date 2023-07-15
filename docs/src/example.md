# Example

Todo:

* implementation: hole: radial allowance, plane: axial allowance (different from the paper)
* API extension should be described, as it is major feature of the package

## Example part

The following part is crafted for demonstrating purposes.
The CAD filesa are available here: [machined](../assets/example-part-machined.stl) and [rough](../assets/example-part-rough.stl).
The two images below show the part from its "front" and "back" sides in its machined state.

![Machined look front](../assets/machined-front.png)

![Machined look back](../assets/machined-back.png)

All six holes needs to be machined and also their front faces, which means that there are six machined planes.

The part in its rough (to be machined) state is shown below:

![Rough look front](../assets/rough-front.png)

![Rough look back](../assets/rough-back.png)

The rough part is also designed in CAD, of course in production the dimensions of the rough part come from a measurement process.
It can be seen, that the holes on the rough part are smaller, and their axes' are also modified a little bit in a few cases to showcase the possibilities of the algorithm.

## Part zeros

There are three part zeros, their attributes are listed in the table below.
Their axes' are shown relative to the workpiece datum.

| Part zero name | x axis | y axis | z axis |
| --- | --- | --- | --- |
| front | y | z | x |
| right | -x | z | y |
| back | -y | z | -x |

They can be defined in julia like this.

```julia
using BlankLocalizationCore

## Part zero definitions

pzf = PartZero("front", [0,0,0], hcat([0,1,0], [0,0,1], [1,0,0]))
pzr = PartZero("right", [0,0,0], hcat([-1, 0, 0], [0, 0, 1], [0, 1, 0]))
pzb = PartZero("back", [0,0,0], hcat([0, -1, 0], [0, 0, 1], [-1, 0, 0]))

partzeros = [pzf, pzr, pzb]
```

When constructing a part zero, a default `[0,0,0]` positions is set, as the goal of the optimization process is to find the values of those positions.
For more details see the docs of [`PartZero`](@ref).

## Machined features

The following are the features' positions (six holes and six faces):

| Name | Part zero name | Position (relative to part zero) | Radius (if hole) |
| --- | --- | --- | --- |
| front hole | front | [0, 0, 0] | 29 |
| front face | front | [0, 0, 0] |  |
| right hole 1 | right | [16, 15, 0] | 7.5 |
| right hole 2 | right | [25, -16, 3] | 9 |
| right hole 3 | right | [60, 0, -3] | 13.5 |
| right face 1 | right | [16, 15, 0] |  |
| right face 2 | right | [25, -16, 3] |  |
| right face 3 | right | [60, 0, -3] |  |
| back hole 1 | back | [-14, 14, 0] | 9 |
| back hole 2 | back | [14, 14, 0] | 9 |
| back face 1 | back | [-14, 14, 0] |  |
| back face 2 | back | [14, 14, 0] |  |

The machined geometries are represented with primitive features, and can be done this way:

```julia
## Machined geometry definitions

fronthole_m = SimpleHole([0, 0, 0], 29)
frontface_m = SimplePlane([0, 0, 0])

righthole1_m = SimpleHole([16, 15, 0], 7.5)
righthole2_m = SimpleHole([25, -16, 3], 9)
righthole3_m = SimpleHole([60, 0, -3], 13.5)
rightface1_m = SimplePlane([16, 15, 0])
rightface2_m = SimplePlane([25, -16, 3])
rightface3_m = SimplePlane([60, 0, -3])

backhole1_m = SimpleHole([-14, 14, 0], 9)
backhole2_m = SimpleHole([14, 14, 0], 9)
backface1_m = SimplePlane([-14, 14, 0])
backface2_m = SimplePlane([14, 14, 0])
```

Holes are defined with their CNC machining position relative to their corresponding part zero, and their radius.
Planes are defined with their position relative to their part zero.
Orientation of the hole axes and plane normals are defined by their part zero (z axis).

## Rough features

The rough features are measured relative to the workpiece datum and are listed below.

| Name | Position (relative to part zero) | Radius (if hole) |
| --- | --- | --- |
| front hole | [82.5, 30, 40] | 26 |
| front face | [82.5, 30, 40] |  |
| right hole 1 | [66, 71.5, 55] | 6 |
| right hole 2 | [58, 74.5, 24] | 4.905 |
| right hole 3 | [21.5, 68.5, 40] | 16 |
| right face 1 | [66, 71.5, 55] |  |
| right face 2 | [58, 74.5, 24] |  |
| right face 3 | [21.5, 68.5, 40] |  |
| back hole 1 | [-3, 44, 53.9] | 6.2 |
| back hole 2 | [-3, 16.1, 54] | 6.25 |
| back face 1 | [-3, 44, 54] |  |
| back face 2 | [-3, 16, 54] |  |

In julia we define primitive features just like before.

```julia
## Rough geometry definitions

fronthole_r = SimpleHole([82.5, 30, 40], 26)
frontface_r = SimplePlane([82.5, 30, 40])

righthole1_r = SimpleHole([66, 71.5, 55], 6)
righthole2_r = SimpleHole([58, 74.5, 24], 4.905)
righthole3_r = SimpleHole([21.5, 68.5, 40], 8)
rightface1_r = SimplePlane([66, 71.5, 55])
rightface2_r = SimplePlane([58, 74.5, 24])
rightface3_r = SimplePlane([21.5, 68.5, 40])

backhole1_r = SimpleHole([-3, 44, 53.9], 6.2)
backhole2_r = SimpleHole([-3, 16.1, 54], 6.25)
backface1_r = SimplePlane([-3, 44, 54])
backface2_r = SimplePlane([-3, 16, 54])
```

## Pairing the rough and machined features

To create [`LocalizationFeature`](@ref)s, that will be subject to the optimizatio, a [`FeatureDescriptor`](@ref) is needed to be defined for each.
This "joins" a rough and machined geometry, and contains information such as the name and part zero of the feature and if a feature has a machined and rough state.
(There are cases, when this can be important, for this example all features have machined and rough state).

This will look like this in julia:

```julia
## Geometry pairing and feature descriptors

# Feature descriptors for each feature

fd_fronthole = FeatureDescriptor("fronthole", pzf, true, true)
fd_frontface = FeatureDescriptor("frontface", pzf, true, true)

fd_righthole1 = FeatureDescriptor("righthole1", pzr, true, true)
fd_righthole2 = FeatureDescriptor("righthole2", pzr, true, true)
fd_righthole3 = FeatureDescriptor("righthole3", pzr, true, true)
fd_rightface1 = FeatureDescriptor("rightface1", pzr, true, true)
fd_rightface2 = FeatureDescriptor("rightface2", pzr, true, true)
fd_rightface3 = FeatureDescriptor("rightface3", pzr, true, true)

fd_backhole1 = FeatureDescriptor("backhole1", pzb, true, true)
fd_backhole2 = FeatureDescriptor("backhole2", pzb, true, true)
fd_backface1 = FeatureDescriptor("backface1", pzb, true, true)
fd_backface2 = FeatureDescriptor("backface2", pzb, true, true)

# Hole features

holes = [HoleLocalizationFeature(fd_fronthole, fronthole_r, fronthole_m),
    HoleLocalizationFeature(fd_righthole1, righthole1_r, righthole1_m),
    HoleLocalizationFeature(fd_righthole2, righthole2_r, righthole2_m),
    HoleLocalizationFeature(fd_righthole3, righthole3_r, righthole3_m),
    HoleLocalizationFeature(fd_backhole1, backhole1_r, backhole1_m),
    HoleLocalizationFeature(fd_backhole2, backhole2_r, backhole2_m)
    ]

# Face features
planes = [PlaneLocalizationFeature(fd_frontface, frontface_r, frontface_m),
PlaneLocalizationFeature(fd_rightface1, rightface1_r, rightface1_m),
PlaneLocalizationFeature(fd_rightface2, rightface2_r, rightface2_m),
PlaneLocalizationFeature(fd_rightface3, rightface3_r, rightface3_m),
PlaneLocalizationFeature(fd_backface1, backface1_r, backface1_m),
PlaneLocalizationFeature(fd_backface2, backface2_r, backface2_m)
]
```

## Tolerances

A tolerance is described between two feature (their feature point to be precise), and their distance is calculated with a certain projection (usually projection to one of the axis of the workpiece datum, but any R^3->R transformation can be used).
This projected distance must be between the lower and upper values of the tolerance.
Tolerance can be defined between both rough and/or machined features.

For this example, the tolerances are created based on the drawing of the machined part.
This is the drawing, which only contains dimensions related to the optimization problem.
It is also available as a pdf [here](../assets/example-part-machined-tolerances.pdf).

![Tolerances](../assets/example-part-machined-tolerances.png)

| Feature 1 name | Feature 1 is machined/rough | Projection | Feature 2 is machined/rough | Nominal value | Lower value | Upper value | Notes (if any) |
| --- | --- | --- | --- | --- | --- | --- | --- |



## Constructing and solving the optimization problem

A few parameters are needed for the optimization problem, passed to the object as a dictionary.
These are:

| Name (key) | Description | Suggested value | Optional |
| --- | ---  | --- | --- |
| minALlowance | Minimum allowance that must be achieved even by the lowest value. | `0.1` | Obligatory |
| OptimizeForToleranceCenter | The default method is to optimize for the middle (center) of the tolerance fields. For debugging, one can set it to `false`, then the minimum allowance will be maximised (ignoring the `minAllowance` value). | `true` | Obligatory |
| UseTolerances | Also a debugging feature. Tolerance lower-upper values are added as active constraints on the distance of the corresponding features. This can be turned off with this flag. | `true` | Obligatory |
