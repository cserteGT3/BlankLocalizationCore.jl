"""
    transformmachinedgeoms(lf::LocalizationFeature)

Get the rough state of `lf` and transform it according to its current part zero transformation.
"""
function transformmachinedgeoms(lf::LocalizationFeature)
    pz = partzero(lf)
    R = pz.rotation
    rot = RotMatrix{3}(R)
    fr = Rotate(rot)
    ft = Translate(pz.position...)
    geom = visualizationgeometry(geometry(lf.machinedfeature))
    geom2 = fr(geom)
    return ft(geom2)
end

"""
    genmachinedholes(mop::MultiOperationProblem)

Generate Meshes object for each machined hole.
"""
function genmachinedholes(mop::MultiOperationProblem)
    holes = cylindricalfeatures(mop)
    return [transformmachinedgeoms(h) for h in holes]
end

"""
    genroughholes(mop::MultiOperationProblem)

Generate Meshes object for each rough hole.
"""
function genroughholes(mop::MultiOperationProblem)
    holes = cylindricalfeatures(mop)
    return [visualizationgeometry(geometry(h.roughfeature)) for h in holes]
end

"""
    genroughplanes(mop::MultiOperationProblem)

Generate Meshes object for each machined plane.
"""
function genmachinedplanes(mop::MultiOperationProblem)
    planes = planarfeatures(mop)
    return [transformmachinedgeoms(p) for p in planes]
end

"""
    genroughplanes(mop::MultiOperationProblem)

Generate Meshes object for each rough plane.
"""
function genroughplanes(mop::MultiOperationProblem)
    planes = planarfeatures(mop)
    return [visualizationgeometry(geometry(p.roughfeature)) for p in planes]
end
