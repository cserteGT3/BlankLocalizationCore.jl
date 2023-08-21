# BlankLocalizationCore

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cserteGT3.github.io/BlankLocalizationCore.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cserteGT3.github.io/BlankLocalizationCore.jl/dev/)
[![Build Status](https://github.com/cserteGT3/BlankLocalizationCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cserteGT3/BlankLocalizationCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

This repository contains the reference implentation for the multi operation blank localization technique described in our paper _Multi-operation optimal blank localization for near net shape machining_.
The paper is available is here: <https://www.sciencedirect.com/science/article/pii/S0007850623000884>.

The goal of multi operation blank localization is to align the CNC machining code for the rough (e.g. cast, 3D printed, etc.) parts.
When doing so, one must consider two important factors:

- leaving enough material to be removed by the tool (machining allowance)
- respecting the dimensional tolerances between features (defined on the part drawing)

Our paper proposes a method, that ensures a proper machining allowance (minimum requirement), while trying to optimize to the center of the tolerance fields between features.

The documentation goes through a detailed example of the process while showing how to use the package.

The package is registered in the general registry, so it can be installed via running:

```julia
]
add BlankLocalizationCore
```

## Design goals

This is a one on one implementation of the optimization model described in the above mentioned paper.
As processing different types of measurement data (such as coordinate measurement machine, or a 3D scanner) requires different methods and techniqes, a well designed interface is available.
The aim is to make it easy to adapt our methodology to any measurement types available.

If you use find this work useful, please cite our paper:

```txt
@article{cserteg:2023_MultioperationOptimalBlank,
  title = {Multi-Operation Optimal Blank Localization for near Net Shape Machining},
  author = {Cserteg, Tamás and Kovács, András and Váncza, József},
  year = {2023},
  month = jun,
  journal = {CIRP Annals},
  issn = {0007-8506},
  doi = {10.1016/j.cirp.2023.04.049},
}
```

## Acknowledgements

This package couldn't have been created without the great people behind the following projects (as well as the whole Julia ecosystem):

* [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl), [MeshViz.jl](https://github.com/JuliaGeometry/MeshViz.jl) and the [Makie.jl](https://github.com/MakieOrg/Makie.jl) ecosystem
* [JuMP.jl](https://jump.dev/)
* [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) and [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl)

<!---
To build the paper, use this site: https://whedon.theoj.org/
--->
