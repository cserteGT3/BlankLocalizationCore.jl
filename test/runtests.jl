using BlankLocalizationCore
using Test

using Meshes
using Ipopt

const BLC = BlankLocalizationCore

using Aqua
Aqua.test_all(BlankLocalizationCore)

include("partzeros.jl")
include("geometries.jl")
include("testproblem.jl")
