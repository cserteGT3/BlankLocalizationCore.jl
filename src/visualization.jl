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

"""
    genroughplanes(mop::MultiOperationProblem, sidelength=20)

Generate `Meshes.SimpleMesh`s for each rough plane.
"""
function genroughplanes(mop::MultiOperationProblem, sidelength=20)
    geoms = SimpleMesh[]
    for plane in collectmachinedplanes(mop)
        pz = getpartzero(plane)
        T = getpartzeroHM(pz)
        R = T[1:3, 1:3]
        o = getroughfeaturepoint(plane)
        c1 = R*[sidelength/2, -sidelength/2, 0]
        c2 = c1 + R*[-sidelength, 0, 0]
        c3 = c2 + R*[0, sidelength, 0]
        c4 = c3 + R*[sidelength, 0, 0]
        

        g1 = Point3(o+Vec3(c1))
        g2 = Point3(o+Vec3(c2))
        g3 = Point3(o+Vec3(c3))
        g4 = Point3(o+Vec3(c4))
        sm = SimpleMesh([g1,g2,g3,g4], connect.([(1,2,3),(3,4,1)]))
        push!(geoms, sm)
    end
    return geoms
end


"""
    genmachinedplanes(mop::MultiOperationProblem, sidelength=20)

Generate `Meshes.SimpleMesh`s for each machined plane.
"""
function genmachinedplanes(mop::MultiOperationProblem, sidelength=20)
    geoms = SimpleMesh[]
    for plane in collectmachinedplanes(mop)
        pz = getpartzero(plane)
        o = getmachinedfeaturepoint(plane)
        c1 = o + [sidelength/2, -sidelength/2, 0]
        c2 = c1 + [-sidelength, 0, 0]
        c3 = c2 + [0, sidelength, 0]
        c4 = c3 + [sidelength, 0, 0]
        R = getpartzeroHM(pz)
        p1 = R*HV(c1)
        p2 = R*HV(c2)
        p3 = R*HV(c3)
        p4 = R*HV(c4)

        g1 = Point3(p1[1:3])
        g2 = Point3(p2[1:3])
        g3 = Point3(p3[1:3])
        g4 = Point3(p4[1:3])
        sm = SimpleMesh([g1,g2,g3,g4], connect.([(1,2,3),(3,4,1)]))
        push!(geoms, sm)
    end
    return geoms
end