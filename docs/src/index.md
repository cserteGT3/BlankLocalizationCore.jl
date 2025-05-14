```@meta
CurrentModule = BlankLocalizationCore
```

# BlankLocalizationCore

This repository contains the reference implentation for the multi operation blank localization technique described in our paper _Multi-operation optimal blank localization for near net shape machining_.
The paper is available is here: <https://www.sciencedirect.com/science/article/pii/S0007850623000884>.

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

## Blank localization briefly

The goal of multi operation blank localization is to align the CNC machining code for the rough (e.g. cast, 3D printed, etc.) parts.
When doing so, one must consider two important factors:

- leaving enough material to be removed by the tool (machining allowance)
- respecting the dimensional tolerances between features (defined on the part drawing)

Our paper proposes a method, that ensures a proper machining allowance (minimum requirement), while trying to optimize to the center of the tolerance fields between features.

## Installation and usage

The package is registered in the general registry, so it can be installed via running:

```julia
using Pkg
Pkg.add("BlankLocalizationCore")
```

Note, that an optimization solver is needed to use the package (Ipopt or Xpress for example), which needs to be installed as well:

```julia
Pkg.add("Ipopt") # open source solver
# Pkg.add("Xpress") # commercial solver, that requires purchased/community license
```

For the exaplanation on how the package works, see the followings:

- [First steps](https://github.com/cserteGT3/BlankLocalizationCore.jl?tab=readme-ov-file#first-steps) in the Readme: short example with copy-paste code.
- [Short 2D example](@ref): the same example in the documentation with a bit more details.
- [Complex 3D example](@ref): a complex, detailed 3D example showcasing the full potential of the package.


## Acknowledgements

This package couldn't have been created without the great people behind the following projects (as well as the whole Julia ecosystem):

* [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) and the [Makie.jl](https://github.com/MakieOrg/Makie.jl) ecosystem
* [JuMP.jl](https://jump.dev/)
* [DataFrames.jl](https://github.com/JuliaData/DataFrames.jl) and [PrettyTables.jl](https://github.com/ronisbr/PrettyTables.jl)

## Related literature

Our work has been published in several papers, one of them is still in print.
The list (in chronological order):

* _Digital twin assisted workpiece referencing for compensating the stock deviation of casted parts_: [link to paper](https://www.sciencedirect.com/science/article/pii/S2212827123002743)
* _Multi-operation optimal blank localization for near net shape machining_: [link to paper](https://www.sciencedirect.com/science/article/pii/S0007850623000884)
* _Multi-operation blank localization with hybrid point cloud and feature-based representation_: [link to paper](https://www.sciencedirect.com/science/article/pii/S221282712300803X)
