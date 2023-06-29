# BlankLocalizationCore

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cserteGT3.github.io/BlankLocalizationCore.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cserteGT3.github.io/BlankLocalizationCore.jl/dev/)
[![Build Status](https://github.com/cserteGT3/BlankLocalizationCore.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cserteGT3/BlankLocalizationCore.jl/actions/workflows/CI.yml?query=branch%3Amain)

This repository contains the reference implentation for the multi operation blank localization technique described in our paper _Multi-operation optimal blank localization for near net shape machining_.
The paper is available is here: <https://www.sciencedirect.com/science/article/pii/S0007850623000884>.
If you use find this work useful, please cite the paper:

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

## Multi operation blank localization summary

## Design goals

_Note_: minimum required Julia version is 1.6 due to StaticArrays.jl dependency!

This is a one on one implementation of the optimization model described in the above mentioned paper.
As processing different types of measurement data (such as coordinate measurement machine, or a 3D scanner) requires different methods and techniqes, a well designed interface is available.
The aim is to make it easy to adapt our methodology to any measurement types available.
