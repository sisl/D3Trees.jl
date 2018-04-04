module D3Trees

using JSON
using Blink
using AbstractTrees
import AbstractTrees: printnode

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
    options::Dict{Symbol, Any}
end

"""
    D3Tree(children, <keyword arguments>)

Construct a tree to be displayed using D3 in a browser or ipython notebook.

# Arguments

## Required

- `children::Vector{Vector{Int}}`: List of children for each node. E.g.
  ```julia
  D3Tree([[2,3], [], [4], []])
  ```
  creates a tree with four nodes. Nodes 2 and 3 are children of node 1, and node 4 is the only child of node 3. Nodes 2 and 4 are childless.

## Keyword:
- `text::Vector{String}` - text to appear under each node.
- `tooltip::Vector{String}` - text to appear when hovering over each node.
- `style::Vector{String}` - html style for each node.
- `link_style::Vector{String}` - html style for each link.
- `title::String` - html title.
- `init_expand::Integer` - levels to expand initially.
- `init_duration::Number` - duration of the initial animation in ms.
- `svg_height::Number` - height of the svg containing the tree in px.
"""
function D3Tree(children::AbstractVector{<:AbstractVector}; kwargs...)
    kwd = Dict(kwargs)
    n = length(children)
    return D3Tree(children,
                  get(kwd, :text, collect(string(i) for i in 1:n)),
                  get(kwd, :tooltip, fill("", n)),
                  get(kwd, :style, fill("", n)),
                  get(kwd, :link_style, fill("", n)),
                  get(kwd, :title, "Julia D3Tree"),
                  convert(Dict{Symbol, Any}, kwd)
                 )
end

"""
    D3Tree(node; detect_repeat=true)

Construct a tree to be displayed using D3 in a browser or ipython notebook from any object that implements the AbstractTrees interface.

# Arguments

## Required

- `node`: an object that has AbstractTrees.children(node) and AbstractTrees.printnode(io::IO, node)

## Keyword

- `detect_repeat`: if true, uses a dictionary to detect whether a node has appeared previously
"""
function D3Tree(node; detect_repeat::Bool=true)
    t = D3Tree(Vector{Int}[])
    if detect_repeat
        node_dict = Dict{Any, Int}()
        push_node!(t, node, node_dict)
    else
        push_node!(t, node)
    end
    return t
end

function push_node!(t, node, node_dict=nothing)
    if !(node_dict isa Void) && haskey(node_dict, node)
        return node_dict[node]
    end

    ind = length(t.children) + 1
    if !(node_dict isa Void)
        node_dict[node] = ind
    end
    if length(t.children) < ind
        push!(t.children, Int[])
        iob = IOBuffer()
        printnode(iob, node)
        push!(t.text, String(take!(iob)))
    end
    for c in children(node)
        c_ind = push_node!(t, c, node_dict)
        push!(t.children[ind], c_ind)
    end
    return ind
end

struct D3TreeNode
    tree::D3Tree
    index::Int
end

AbstractTrees.children(n::D3TreeNode) = (D3TreeNode(n.tree, c) for c in n.tree.children[n.index])
AbstractTrees.children(t::D3Tree) = children(D3TreeNode(t, 1))
n_children(n::D3TreeNode) = length(n.tree.children[n.index])
AbstractTrees.printnode(io::IO, n::D3TreeNode) = print(io, n.tree.text[n.index])

struct D3TreeView
    root::D3TreeNode
    depth::Int
end

include("show.jl")
include("displays.jl")
include("text.jl")

end # module
