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
    tooltip::Vector{String}
    style::Vector{String}
    link_style::Vector{String}
end

function D3Tree(children; kwargs...)
    kwd = Dict(kwargs)
    n = length(children)
    return D3Tree(children,
                  get(kwd, :text, fill("", n)),
                  get(kwd, :tooltip, fill("", n)),
                  get(kwd, :style, fill("", n)),
                  get(kwd, :link_style, fill("", n))
                 )
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
