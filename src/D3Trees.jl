module D3Trees

using JSON
using Blink

export
    D3Tree,
    D3TreeNode,
    D3TreeView,

    blink,
    inchrome

struct D3Tree
    children::Vector{Vector{Int}}
    text::Vector{String}
    tooltip::Vector{String}
    style::Vector{String}
    link_style::Vector{String}
    title::String
    init_expanded::Bool
end

function D3Tree(children; kwargs...)
    kwd = Dict(kwargs)
    n = length(children)
    return D3Tree(children,
                  get(kwd, :text, collect(string(i) for i in 1:n)),
                  get(kwd, :tooltip, fill("", n)),
                  get(kwd, :style, fill("", n)),
                  get(kwd, :link_style, fill("", n)),
                  get(kwd, :title, "Julia D3Tree"),
                  get(kwd, :init_expanded, false)
                 )
end
    
struct D3TreeNode
    tree::D3Tree
    index::Int
end

# this should be AbstractTrees.children
children(n::D3TreeNode) = (D3TreeNode(n.tree, c) for c in n.tree.children[n.index])
n_children(n::D3TreeNode) = length(n.tree.children[n.index])
# this should be AbstractTrees.printnode
printnode(io::IO, n::D3TreeNode) = print(io, n.tree.text[n.index])

struct D3TreeView
    root::D3TreeNode
    depth::Int
end

include("show.jl")
include("displays.jl")
include("text.jl")

end # module
