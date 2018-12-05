module D3Trees

using JSON
#using Blink
using Random
using AbstractTrees

import AbstractTrees: printnode

export
    D3Tree,
    D3TreeNode,
    D3TreeView,

    blink,
    inchrome,
    inbrowser

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
    D3Tree(node; detect_repeat=true, kwargs...)

Construct a tree to be displayed using D3 in a browser or ipython notebook with any object, `node`, that implements the AbstractTrees interface.

The style may be controlled by implementing the following functions, which should return `String`s for the nodes:
```@docs
D3Trees.text(node)
D3Trees.tooltip(node)
D3Trees.style(node)
D3Trees.link_style(node)
```

# Arguments

## Required

- `node`: an object that has AbstractTrees.children(node) and AbstractTrees.printnode(io::IO, node)

## Keyword

- `detect_repeat`: if true, uses a dictionary to detect whether a node has appeared previously
- Also supports, the non-vector arguments of the vector-of-vectors `D3Tree` constructor, i.e. `title`, `init_expand`, `init_duration`, `svg_height`.
"""
function D3Tree(node; detect_repeat::Bool=true, kwargs...)

    t = D3Tree(Vector{Int}[]; kwargs...)

    if detect_repeat
        node_dict = Dict{Any, Int}()
        push_node!(t, node, node_dict)
    else
        push_node!(t, node)
    end
    return t
end


"""
    D3Tree(children, <keyword arguments>)

Construct a tree to be displayed using D3 in a browser or ipython notebook, specifying structure with lists of children indices.

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
    D3Trees.text(n)

Return the text to be displayed at the D3Trees node corresponding to AbstractTrees node `n`
"""
text(node) = sprint(printnode, node)

"""
    D3Trees.tooltip(n)

Return the text to be displayed in the tooltip for the D3Trees node corresponding to AbstractTrees node `n`
"""
tooltip(node) = sprint(printnode, node)

"""
    D3Trees.style(n)

Return the html style for the D3Trees node corresponding to AbstractTrees node `n`
"""
style(node) = ""

"""
    D3Trees.link_style(n)

Return the html style for the link leading to the D3Trees node corresponding to AbstractTrees node `n`
"""
link_style(node) = ""

struct D3TreeNode
    tree::D3Tree
    index::Int
end

AbstractTrees.children(n::D3TreeNode) = (D3TreeNode(n.tree, c) for c in n.tree.children[n.index])
AbstractTrees.children(t::D3Tree) = children(D3TreeNode(t, 1))
n_children(n::D3TreeNode) = length(n.tree.children[n.index])
AbstractTrees.printnode(io::IO, n::D3TreeNode) = print(io, n.tree.text[n.index])
AbstractTrees.printnode(io::IO, t::D3Tree) = print(io, t.text[1])
tooltip(n::D3TreeNode) = n.tree.tooltip[n.index]
tooltip(t::D3Tree) = t.tooltip[1]
style(n::D3TreeNode) = n.tree.style[n.index]
style(t::D3Tree) = t.style[1]
link_style(n::D3TreeNode) = n.tree.link_style[n.index]
link_style(t::D3Tree) = t.link_style[1]


struct D3TreeView
    root::D3TreeNode
    depth::Int
end

function push_node!(t, node, node_dict=nothing)
    if !(node_dict == nothing) && haskey(node_dict, node)
        return node_dict[node]
    end

    ind = length(t.children) + 1
    if !(node_dict == nothing)
        node_dict[node] = ind
    end
    if length(t.children) < ind
        push!(t.children, Int[])
        push!(t.text, text(node))
        push!(t.tooltip, tooltip(node))
        push!(t.style, style(node))
        push!(t.link_style, link_style(node))
    end
    for c in children(node)
        c_ind = push_node!(t, c, node_dict)
        push!(t.children[ind], c_ind)
    end
    return ind
end


include("show.jl")
include("displays.jl")
include("text.jl")

end # module
