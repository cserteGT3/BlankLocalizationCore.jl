## part zero handling and transformations

struct PartZero
    name::String
    position::Vector{Float64}
    rotation::Matrix{Float64}
end

Base.show(io::IO, pz::PartZero) = print(io, "Part zero: \"", pz.name, "\"")

Base.show(io::IO, ::MIME"text/plain", pz::PartZero) = print(io, "Part zero: \"", pz.name, "\"\n", getpartzeroHM(pz))

xaxis(partzero::PartZero) = partzero.rotation[:,1]
yaxis(partzero::PartZero) = partzero.rotation[:,2]
zaxis(partzero::PartZero) = partzero.rotation[:,3]


"""
    getpartzeroHM(partzero::PartZero)

Get homogeneous matrix of part zero `partzero`.
"""
function getpartzeroHM(partzero::PartZero)
    return vcat(hcat(partzero.rotation, partzero.position), [0 0 0 1])
end

"""
    getpartzeroinverseHM(partzero::PartZero)

Get the inverse homogeneous matrix of part zero `partzero`.
"""
function getpartzeroinverseHM(partzero::PartZero)
    invtr = zeros(Float64,4,4)
    invtr[4,4] = 1
    R = partzero.rotation
    invR = inv(R)
    invtr[1:3, 1:3] = invR
    invtr[1:3, 4] = -1*invR*partzero.position
    return invtr
end

"""
    inverthomtr(M)

Invert a homogeneous transformation matrix.
"""
function inverthomtr(M)
    invtr = zeros(Float64,4,4)
    invtr[4,4] = 1
    R = M[1:3, 1:3]
    invR = inv(R)
    invtr[1:3, 1:3] = invR
    invtr[1:3, 4] = -1*invR*M[1:3,4]
    return invtr
end


"""
    getpartzerobyname(partzeros::Vector{PartZero}, partzeroname::AbstractString)

Return the first part zero from `partzeros`, thats name is `partzeroname`.
"""
function getpartzerobyname(partzeros::Vector{PartZero}, partzeroname::AbstractString)
    for pz in partzeros
        pz.name == partzeroname && return pz
    end
    return nothing
end

"""
    getcoordinateindatumorientation(partzero::PartZero, v, axis::Int)

Get the `axis`th coordinate of vector `v` in the orientation of the workpiece datum.
(Inverse transformed with the part zero, the part zero's position being zero.)
"""
function getcoordinateindatumorientation(partzero::PartZero, v, axis::Int)
    M = getpartzeroHM(partzero)
    M[1:3,4] = [0,0,0]
    #iM = inv(M)
    fv = M*vcat(v, 1)
    # not sure why, but part zero is needed, not its inverted part
    #fv = iM*vcat(v, 1)
    return fv[axis]
end

"""
    printpartzeropositions(partzeros::Vector{PartZero})

Print the positions of an array of part zeros.
"""
function printpartzeropositions(partzeros::Vector{PartZero})
    for pz in partzeros
        println(pz.name, ": ", pz.position)
    end
end
