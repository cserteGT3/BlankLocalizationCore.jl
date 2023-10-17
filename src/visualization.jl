"""
    transformmachinedgeoms(lf::LocalizationFeature)

Get the rough state of `lf` and transform it according to its current part zero transformation.
"""
function transformmachinedgeoms(lf::LocalizationFeature)
    pz = getpartzero(lf)
    R = pz.rotation
    rot = RotMatrix{3}(R)
    fr = Rotate(rot)
    ft = Translate(pz.position...)
    geom = visualizationgeometry(lf.machined)
    geom2 = fr(geom)
    return ft(geom2)
end

"""
    genmachinedholes(mop::MultiOperationProblem)

Generate Meshes object for each machined hole.
"""
function genmachinedholes(mop::MultiOperationProblem)
    holes = collectmachinedholes(mop)
    # reimplement transformmachinedgeoms, because:
    # https://github.com/JuliaGeometry/Meshes.jl/issues/622
    disks = Disk[]
    for h in holes
        pz = getpartzero(h)
        R = pz.rotation
        rot = RotMatrix{3}(R)
        fr = Rotate(rot)
        ft = Translate(pz.position...)
        geom = visualizationgeometry(h.machined)
        rotg = fr(geom)
        trg = ft(rotg)
        finalg = Disk(Plane(trg.plane.p, rotg.plane.u, rotg.plane.v), trg.radius)
        push!(disks, finalg)
    end
    return disks
end

"""
    genroughholes(mop::MultiOperationProblem)

Generate Meshes object for each rough hole.
"""
function genroughholes(mop::MultiOperationProblem)
    holes = collectroughholes(mop)
    return [visualizationgeometry(h.rough) for h in holes]
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
