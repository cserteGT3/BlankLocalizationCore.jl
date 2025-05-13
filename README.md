# BlankLocalizationCore

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cserteGT3.github.io/BlankLocalizationCore.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cserteGT3.github.io/BlankLocalizationCore.jl/dev/)
[![Build Status](https://github.com/cserteGT3/BlankLocalizationCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cserteGT3/BlankLocalizationCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

## Project description

This repository contains the reference implentation for the multi operation blank localization technique described in our paper [_Multi-operation optimal blank localization for near net shape machining_](https://www.sciencedirect.com/science/article/pii/S0007850623000884).

The goal of multi operation blank localization is to align the CNC machining code for the rough (e.g. cast, 3D printed, etc.) parts.
When doing so, one must consider two important factors:

- leaving enough material to be removed by the tool (machining allowance)
- respecting the dimensional tolerances between features (defined on the part drawing)

Our paper proposes a method, that ensures a proper machining allowance (minimum requirement), while trying to optimize to the center of the tolerance fields between features.

## Installation and usage

The package is registered in the general registry, so it can be installed via running:

```julia
] add BlankLocalizationCore
```

For the exaplanation on how the package works, please read through the [Example](https://csertegt3.github.io/BlankLocalizationCore.jl/stable/example/) page of the documentation.

Note, that at least Julia 1.9 is required.
If you are interested in using the package with older versions, please open an issue!

## First steps

For a bit more details, see the [documentation version](https://csertegt3.github.io/BlankLocalizationCore.jl/stable/example-2d/) of the following example.

The task is to find optimal positions for drilling the three holes on one side of the part.
The three holes are machined in one operation: the machining poses are defined to a common part zero.
The distance of the holes and another side of the part is toleranced (only along one, the x axis).
In this example we are searching the optimal x value of the part zero (and are ignoring the y-z values for simplicity).
We mean optimal in the sense that, 1) material must be removed at every hole (the blue circles must cover the black ones with enough margin called machining allowance) and 2) the toleranced distances between the left plane and the holes should be as close to the center of the tolerance fields as possible.
Please note, that the package is designed for 3D usage, therefore the geometry defintions need to have all coordinates defined (even though this example is a planar problem).

![example-2d](docs/src/assets/example-2d.png)

### Installation

Install the package and a solver.

```julia
using Pkg
Pkg.add(["BlankLocalizationCore", "Ipopt"])
```

### Model building

```julia
using BlankLocalizationCore

# partzero relative to origin:
# translation: zero, will be calculated by optimization
# orientation: given as rotation matrices
pz_holes = PartZero("pz-holes", [0,0,0], hcat([1,0,0], [0,1,0], [0,0,1]))

# machined features: 3 holes + 1 dummy plane
h1 = SimpleHole([62, 7, 0], 11.5)
h2 = SimpleHole([80, 52, 0], 13)
h3 = SimpleHole([108, 26, 0], 12.5)
p1 = SimplePlane([0, 0, 0]) # just a dummy

# rough features: 3 holes
# measured relative to origin
rh1 = HoleAndNormal([-56.79, 44.235, 0], [0, 0, -1], 11.2)
rh2 = HoleAndNormal([-38.79, 89.235, 0], [0, 0, -1], 12.8)
rh3 = HoleAndNormal([-10.79, 63.235, 0], [0, 0, -1], 12.2)
rp1 = PlaneAndNormal([-125.67, 66, 0], [-1, 0, 0])

# feature descriptors
fd1 = FeatureDescriptor("hole1", pz_holes, true, true)
fd2 = FeatureDescriptor("hole2", pz_holes, true, true)
fd3 = FeatureDescriptor("hole3", pz_holes, true, true)
fd4 = FeatureDescriptor("left-plane", pz_holes, false, true)

# tolerances

xfunc(x) = x[1]
tolerances = [
    Tolerance("hole1", true, xfunc, "left-plane", false, 69, 68.5, 69.5, ""),
    Tolerance("hole2", true, xfunc, "left-plane", false, 87, 86.7, 87.3, ""),
    Tolerance("hole3", true, xfunc, "left-plane", false, 115, 114.8, 115.2, "")
]

# localization features: a descriptor and a rough and machined geometry
holes = [
    HoleLocalizationFeature(fd1, rh1, h1),
    HoleLocalizationFeature(fd2, rh2, h2),
    HoleLocalizationFeature(fd3, rh3, h3),
]

planes = [
    PlaneLocalizationFeature(fd4, rp1, p1)
]

# dictionary of model parameters
pard = Dict("minAllowance"=>0.1, "OptimizeForToleranceCenter"=>true,
    "UseTolerances"=>true, "maxPlaneZAllowance"=>1);

# variable that defines all geometries and parameters for the optimization problem
mop = MultiOperationProblem([pz_holes], holes, planes, tolerances, pard)
```

### Model solving and evaluation

```julia
import Ipopt
# generating the optimization program based on the definition and passsing to the solver
optimizeproblem!(mop, Ipopt.Optimizer)

# printing the resulting part zero positions
printpartzeropositions(mop)
# printing table containing the allowance calculation results
printallowancetable(mop)
# printing table containing the tolerance calculation results
printtolerancetable(mop)
```

## Contributing

Contributions are very welcome, as are feature requests and suggestions.
Please open an issue if you encounter any problems. We take issues seriously and value any type of feedback.

## Acknowledgements

This package couldn't have been created without the great people behind the following projects (as well as the whole Julia ecosystem):

* [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) and the [Makie.jl](https://github.com/MakieOrg/Makie.jl) ecosystem
* [JuMP.jl](https://jump.dev/)
* [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) and [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl)
