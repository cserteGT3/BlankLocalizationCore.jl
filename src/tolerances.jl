"""Supertype of tolerance types."""
abstract type LocalizationToleranceType end

struct PlanePlaneDistance <: LocalizationToleranceType end

struct PlaneAxisDistance <: LocalizationToleranceType end

struct AxisAxisDistance <: LocalizationToleranceType
    projectionaxis::Vector{Float64}
end

struct AxisAxisConcentric <: LocalizationToleranceType end

"""
    toleranceddistance

Should have signature like:
`toleranceddistance(type::LocalizationToleranceType, feature1, machined1, feature2, machined2)`.
"""
function toleranceddistance end

"""
    getfeaturepoints(x::T)

Get points of a geometry. If it's `IsPrimitive`,
then return the feature point wrapped in an array.
If it's `IsFreeForm`, then return the surface points in an array.
"""
getfeaturepoints(x::T) where {T} = getfeaturepoints(GeometryStyle(T), x)
getfeaturepoints(::IsPrimitive, x) = [featurepoint(x)]
getfeaturepoints(::IsFreeForm, x) = surfacepoints(x)

"""Enum to store if a feature should be handled as rough or machined."""
@enum IsMachined MACHINED ROUGH


struct LocalizationTolerance
    feature1::LocalizationFeature
    machined1::IsMachined
    feature2::LocalizationFeature
    machined2::IsMachined
    type::LocalizationToleranceType
    nominalvalue::Float64
    lowervalue::Float64
    uppervalue::Float64
    note::String
end

function toleranceddistance(type::PlanePlaneDistance, t::LocalizationTolerance)
    f1 = t.feature1
    m1 = t.machined1
    f2 = t.feature2
    m2 = t.machined2


    #check if plane normals are parallel
    zaxis1 = zaxis(getpartzero(f1))
    zaxis2 = zaxis(getpartzero(f2))
    if abs(dot(zaxis1, zaxis2)) < cosd(5)
        error("Planes: $(getfeaturename(f1)) and $(getfeaturename(f2)) are not parallel!
            Can't compute `PlanePlaneDistance`")
    end

    v_f1_ = m1 == MACHINED ? getfeaturepoints(f1.machined) : getfeaturepoints(f1.rough)
    v_f2_ = m2 == MACHINED ? getfeaturepoints(f2.machined) : getfeaturepoints(f2.rough)
    v_f1 = m1 == MACHINED ? transformmachined2datum(f1, v_f1_) : v_f1_
    v_f2 = m2 == MACHINED ? transformmachined2datum(f2, v_f2_) : v_f2_

    # pairwise distance
    #TODO: not good for two IsFreeForm surfaces!!!!
    difference_vectors = (v2-v1 for v1 in v_f1 for v2 in v_f2)
    signed_distances = (dot(zaxis1, dv) for dv in difference_vectors)
    d = mean(abs.(signed_distances))
    return d
end

function toleranceddistance(type::PlaneAxisDistance, t::LocalizationTolerance)
    f1 = t.feature1
    m1 = t.machined1
    f2 = t.feature2
    m2 = t.machined2
    # this is rather plane-point distance
    # 1. get plane normal -> part zero z axis
    # 2. get feature point of both features
    # 3. compute the distance of the feature points
    # 4. project the distance to the z axis
    
    # current implementation only handles IsPrimitive features
    geom1 = m1 == MACHINED ? f1.machined : f1.rough
    geom2 = m2 == MACHINED ? f2.machined : f2.rough
    gs1 = GeometryStyle(typeof(geom1))
    gs2 = GeometryStyle(typeof(geom2))

    if (gs1) != IsPrimitive() || gs2 != IsPrimitive()
        error("PlaneAxisDistance is only implemented when both features are IsPrimitive!
        f1 is $gs1, f2 is $gs2")
    end

    if ! (geom1 isa AbstractPlaneGeometry) || ! (geom2 isa AbstractHoleGeometry)
        error("PlaneAxisDistance is defined for a plane and a hole.
        Got types: $(typeof(geom1)) and $(typeof(geom2))")
    end

    plane_n = zaxis(getpartzero(f1))
    fp_plane = m1 == MACHINED ? getmachinedfeaturepointindatum(f1) : getroughfeaturepoint(f1)
    fp_hole = m2 == MACHINED ? getmachinedfeaturepointindatum(f2) : getroughfeaturepoint(f2)

    distancev = fp_plane - fp_hole
    distance = abs(dot(plane_n, distancev))
    
    return distance
end

function toleranceddistance(type::AxisAxisDistance, t::LocalizationTolerance)
    f1 = t.feature1
    m1 = t.machined1
    f2 = t.feature2
    m2 = t.machined2
    # this is rather point-point distance
    # 1. get feature points
    # 2. get axes of feature points
    # 3. compute the distance of the feature points
    # 4. project the distance along cross product of the two axes
    
    # current implementation only handles IsPrimitive features
    geom1 = m1 == MACHINED ? f1.machined : f1.rough
    geom2 = m2 == MACHINED ? f2.machined : f2.rough
    gs1 = GeometryStyle(typeof(geom1))
    gs2 = GeometryStyle(typeof(geom2))

    if (gs1) != IsPrimitive() || gs2 != IsPrimitive()
        error("AxisAxisDistance is only implemented when both features are IsPrimitive!
        f1 is $gs1, f2 is $gs2")
    end

    if ! (geom1 isa AbstractHoleGeometry) || ! (geom2 isa AbstractHoleGeometry)
        error("AxisAxisDistance is defined for a hole and a hole.
        Got types: $(typeof(geom1)) and $(typeof(geom2))")
    end

    fp1 = m1 == MACHINED ? getmachinedfeaturepointindatum(f1) : getroughfeaturepoint(f1)
    fp2 = m2 == MACHINED ? getmachinedfeaturepointindatum(f2) : getroughfeaturepoint(f2)

    distancev = fp1 - fp2
    distance = abs(dot(type.projectionaxis, distancev))

    return distance
end

function aac_primitive_primitive(f1, m1, f2, m2)
    #check if axes are parallel
    zaxis1 = zaxis(getpartzero(f1))
    zaxis2 = zaxis(getpartzero(f2))
    if abs(dot(zaxis1, zaxis2)) < cosd(5)
        error("Holes' axes are not parallel!
        Can't compute `AxisAxisConcentric` tolerance.")
    end

    fp1 = m1 == MACHINED ? getmachinedfeaturepointindatum(f1) : getroughfeaturepoint(f1)
    fp2 = m2 == MACHINED ? getmachinedfeaturepointindatum(f2) : getroughfeaturepoint(f2)

    # distancev is in workpiece datum
    distancev = fp1 - fp2
    # needs to be in part zero orientation, so the "x-y distance" of the two feature points
    # can be calculated
    iR = inv(getpartzero(f1).rotation)
    dv = iR*distancev
    distance = norm(dv[1:2])

    return distance
end

function aac_primitive_freeform(t::LocalizationTolerance, f1, m1, f2, m2)
    #check if axes are parallel
    # 1. get fp and radius of feature 1
    # 2. get surface points of feature 2
    # 3. calculate the distances from fp1 and surface points of 2
    # 4. subtract t-nominalvalue
    # 5. calculate the mean of those
    zaxis1 = zaxis(getpartzero(f1))
    zaxis2 = zaxis(getpartzero(f2))
    if abs(dot(zaxis1, zaxis2)) < cosd(5)
        error("Holes' axes are not parallel!
        Can't compute `AxisAxisConcentric` tolerance.")
    end
    fp1 = m1 == MACHINED ? getmachinedfeaturepointindatum(f1) : getroughfeaturepoint(f1)
    fp2s = m2 == MACHINED ? transformmachined2datum(f2, surfacepoints(f2.machined)) : surfacepoints(f2.rough)

    # needs to be in part zero orientation, so the "x-y distance" of the two feature points
    # can be calculated
    iR = inv(getpartzero(f1).rotation)
    # distancev is transformed into part zero orientation
    distancevs = (iR*(fp1-v) for v in fp2s)
    # x-y distance is calculated and subtract the t.nominalvalue
    #distances = (norm(v[1:2])-t.nominalvalue for v in distancevs)
    distances = (norm(v[1:2]) for v in distancevs)
    distance = mean(distances)

    return distance
end

function toleranceddistance(type::AxisAxisConcentric, t::LocalizationTolerance)
    f1 = t.feature1
    m1 = t.machined1
    f2 = t.feature2
    m2 = t.machined2
    # this is rather point-point distance
    # 1. get feature points
    # 2. compute the distance of the feature points
    # 4. project the distance to the normal of the axes' of the holes
    
    # current implementation only handles IsPrimitive features
    geom1 = m1 == MACHINED ? f1.machined : f1.rough
    geom2 = m2 == MACHINED ? f2.machined : f2.rough

    if ! (geom1 isa AbstractHoleGeometry) || ! (geom2 isa AbstractHoleGeometry)
        error("AxisAxisConcentric is defined for a hole and a hole.
        Got types: $(typeof(geom1)) and $(typeof(geom2))")
    end

    gs1 = GeometryStyle(typeof(geom1))
    gs2 = GeometryStyle(typeof(geom2))

    if gs1 == IsPrimitive() && gs2 == IsPrimitive()
        # this computes the distance between the axes of two holes
        # ideally this should be zero, so optimizing to tolerance center doesnt really work
        return aac_primitive_primitive(f1, m1, f2, m2)
    elseif gs1 == IsPrimitive() && gs2 == IsFreeForm()
        # this computes the distance between the axis of a hole (part zero z axis) and
        # points of a freeform feature
        return aac_primitive_freeform(t, f1, m1, f2, m2)
    else
        error("AxisAxisConcentric is not only implemented for this pair of geometries!
        f1 is $gs1, f2 is $gs2")
    end   
end


function toleranceddistance(t::LocalizationTolerance)
    toleranceddistance(t.type, t)
end

function evaluatetolerance(t::LocalizationTolerance)
    d = toleranceddistance(t)
    abs_d = d - (t.lowervalue+t.uppervalue)/2
    rel_d = 2*abs_d/(t.uppervalue-t.lowervalue)*100
    return (d, rel_d)
end
