module D3Trees

using JSON
using Blink

export
    D3Tree,

    blink,
    inchrome

struct D3Tree
    children::Vector{Vector{Int}}
    text::Vector{String}
end
    
#=
struct TreeView{T}
    tree::T
    root::Int
    depth::Int
end
=#

struct D3TreeNode
    tree::D3Tree
    index::Int
end

include("show.jl")
include("displays.jl")

end # module
