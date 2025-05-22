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

import Ipopt
# generating the optimization program based on the definition and passsing to the solver
optimizeproblem!(mop, Ipopt.Optimizer)

# printing the resulting part zero positions
printpartzeropositions(mop)
# printing table containing the allowance calculation results
printallowancetable(mop)
# printing table containing the tolerance calculation results
printtolerancetable(mop)

using Meshes
import GLMakie

function initviz(;hideaxes=false)
    f = viz([Point(i, j, k) for i in 0:1 for j in 0:1 for k in 0:1], size=0.01, color=:white)
    if hideaxes
        f.axis.show_axis[] = false
    end
    f
end

rholes = genroughholes(mop)
mholes = genmachinedholes(mop)
mplanes = genmachinedplanes(mop)
rplanes = genroughplanes(mop)

f = initviz(hideaxes=false)
viz!.(rholes, alpha=0.5, color=:red)
viz!.(mholes, alpha=0.5, color=:blue)
viz!.(rplanes, alpha=0.5, color=:red)
viz!.(mplanes, alpha=0.5, color=:blue)
