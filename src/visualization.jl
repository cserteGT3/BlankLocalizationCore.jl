function hole2Mesheshole(partzero::PartZero, featurepoint, radius)
    hole_axis = Vec3(zaxis(partzero))
    # p1: feature point
    p1 = Point3(featurepoint)
    # p2: deeper in the hole
    p2 = p1 - 0.1*hole_axis
    bottom = Plane(p2, hole_axis)
    top = Plane(p1, hole_axis)
    return Cylinder(bottom, top, radius)
end

"""
    genroughholes(mop::MultiOperationProblem)

Generate a `Meshes.Cylinder` object for each rough hole.
The length of the cylinders is really small, they are rather disks.

Wanted to generate `Disk`s, but `viz` is not yet defined for them.
"""
function genroughholes(mop::MultiOperationProblem)
    holes = collectroughholes(mop)
    cylinders = Cylinder[]
    for h in holes
        fp = getroughfeaturepoint(h)
        pz = getpartzero(h)
        r = getroughradius(h)
        cyl = hole2Mesheshole(pz, fp, r)
        push!(cylinders, cyl)
    end
    return cylinders
end

"""
    genmachinedholes(mop::MultiOperationProblem)

Generate a `Meshes.Cylinder` object for each rough hole.
The length of the cylinders is really small, they are rather disks.

Wanted to generate `Disk`s, but `viz` is not yet defined for them.
"""
function genmachinedholes(mop::MultiOperationProblem)
    holes = collectmachinedholes(mop)
    cylinders = Cylinder[]
    for h in holes
        fp = getmachinedfeaturepointindatum(h)
        pz = getpartzero(h)
        r = getmachinedradius(h)
        cyl = hole2Mesheshole(pz, fp, r)
        push!(cylinders, cyl)
    end
    return cylinders
end

## try 2

function transformmachinedgeoms(lf::LocalizationFeature)
    pz = getpartzero(lf)
    R = pz.rotation
    rot = RotMatrix{3}(R)
    # again, I'm not sure about why the inverse...
    fr = Rotate(inv(rot))
    ft = Translate(pz.position...)
    geom = visualizationgeometry(lf.machined)
    geom2 = fr(geom)
    return ft(geom2)
end

# this fails, but this is the way!
# will fix after:
# https://github.com/JuliaGeometry/Meshes.jl/issues/512
# https://github.com/JuliaGeometry/MeshViz.jl/issues/62
function gmholes(mop::MultiOperationProblem)
    holes = collectmachinedholes(mop)
    return [transformmachinedgeoms(h) for h in holes]
end

"""
    genroughplanes(mop::MultiOperationProblem)

Generate Meshes object for each machined plane.
"""
function genmachinedplanes(mop::MultiOperationProblem)
    planes = collectmachinedplanes(mop)
    return [transformmachinedgeoms(p) for p in planes]
end

"""
    genroughplanes(mop::MultiOperationProblem)

Generate Meshes object for each rough plane.
"""
function genroughplanes(mop::MultiOperationProblem)
    planes = collectroughplanes(mop)
    return [visualizationgeometry(p.rough) for p in planes]
end
