## part zero handling and transformations

"""
    PartZero(name, position, rotationmatrix)

Define a part zero with name, position and rotationmatrix relative to the workpiece datum.

# Example

```julia-repl
julia> PartZero("front", [0,0,0], hcat([0,1,0], [0,0,1], [1,0,0]))
Part zero: "front"
[0.0 0.0 1.0 0.0; 1.0 0.0 0.0 0.0; 0.0 1.0 0.0 0.0; 0.0 0.0 0.0 1.0]
```
"""
struct PartZero
    name::String
    position::Vector{Float64}
    rotation::Matrix{Float64}
end

Base.show(io::IO, pz::PartZero) = print(io, "Part zero: \"", pz.name, "\"")

Base.show(io::IO, ::MIME"text/plain", pz::PartZero) = print(io, "Part zero: \"",
    pz.name, "\"\n", getpartzeroHM(pz))

xaxis(partzero::PartZero) = partzero.rotation[:,1]
yaxis(partzero::PartZero) = partzero.rotation[:,2]
zaxis(partzero::PartZero) = partzero.rotation[:,3]

getpartzeroname(pz::PartZero) = pz.name

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
    printpartzeropositions(partzeros::Vector{PartZero})

Print the positions of an array of part zeros.
"""
function printpartzeropositions(partzeros::Vector{PartZero})
    for pz in partzeros
        println(pz.name, ": ", pz.position)
    end
end
