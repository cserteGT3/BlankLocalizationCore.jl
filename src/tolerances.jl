"""Supertype of tolerance types."""
abstract type LocalizationToleranceType end

struct PlanePlaneDistance <: LocalizationToleranceType end

struct PlaneAxisDistance <: LocalizationToleranceType end

struct AxisAxisDistance <: LocalizationToleranceType end

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

"""
    transformmachined2datum(feature, points)

Transform a list of points with the part zero of `feature`.
"""
function transformmachined2datum(feature, points)
    pz = getpartzero(feature)
    M = getpartzeroHM(pz)
    newpoints = (M*HV(p) for p in points)
    resultpoints = [p[1:3] for p in newpoints]
    return resultpoints
end

function toleranceddistance(type::PlanePlaneDistance, f1, m1, f2, m2)
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

function toleranceddistance(type::PlaneAxisDistance, f1, m1, f2, m2)
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


function toleranceddistance(t::LocalizationTolerance)
    toleranceddistance(t.type, t.feature1, t.machined1, t.feature2, t.machined2)
end