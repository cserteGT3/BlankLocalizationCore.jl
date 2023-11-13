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

## Contributing

Contributions are very welcome, as are feature requests and suggestions.
Please open an issue if you encounter any problems. We take issues seriously and value any type of feedback.

## Acknowledgements

This package couldn't have been created without the great people behind the following projects (as well as the whole Julia ecosystem):

* [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) and the [Makie.jl](https://github.com/MakieOrg/Makie.jl) ecosystem
* [JuMP.jl](https://jump.dev/)
* [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) and [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl)
