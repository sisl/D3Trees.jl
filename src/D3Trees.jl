module D3Trees

using JSON
#using Blink - not yet compatible with HTTP.jl v1
using Random
using AbstractTrees

using Sockets
using HTTP

import AbstractTrees: printnode

export
    D3Tree,
    D3TreeNode,
    D3TreeView, blink,
    inchrome,
    inbrowser

struct D3Tree
    children::Vector{Vector{Int}}
    unexpanded_children::Dict{Int,Any}
    text::Vector{String}
    tooltip::Vector{String}
    style::Vector{String}
    link_style::Vector{String}
    title::String
    options::Dict{Symbol,Any}
    frender::NamedTuple{(:text, :tooltip, :style, :link_style)}
end

"""
    D3Tree(node; detect_repeat=true, lazy_expand_after_depth=typemax(Int), kwargs...)

Construct a tree to be displayed using D3 in a browser or ipython notebook with any object, `node`, that implements the AbstractTrees interface. 

The style may be controlled by implementing the following functions, which should return `String`s for the nodes:
```@docs
D3Trees.text(node)
D3Trees.tooltip(node)
D3Trees.style(node)
D3Trees.link_style(node)
```

Allows for lazy loading of large trees through the `lazy_expand_after_depth` keyword argument. Nodes beyonnd this depth are not intially expanded for visualization. 
Instead, they are cached and only expanded when requested by the visualization. The serving is done by the D3Trees HTTP server.

The server does not have information about the lifetime of different visualizations so it might keep references to past visualizations, 
potentially holding up a lot of memory. To reset the server and remove references to old data, run either `D3Trees.reset_server()` or `D3Trees.shutdown_server()`.

# Arguments

## Required

- `node`: an object that has AbstractTrees.children(node) and AbstractTrees.printnode(io::IO, node)

## Keyword

- `detect_repeat`: (default: true) if true, uses a dictionary to detect whether a node has appeared previously
- `lazy_expand_after_depth::Integer`: (default: typemax(Int)). Sets tree depth to at which `AbstractTrees.children(node)` will not be called anymore. Instead, nodes at this depth are cached and `children(node)` is called only when node is clicked in the D3 interactive visualization. Root has depth 0, so setting `lazy_expand_after_depth=1` expands only the root.
- `lazy_subtree_depth::Integer`: (default: 2) sets depth of subtrees fetched from D3Trees server
- `port::Integer`: (default: 16370) specify server port for D3Trees server that will serve subtrees for visualization. Shutdown server by `shutdown_server(port)`.
- `dry_run_lazy_vizualization::Function`: (default: t -> D3Trees.dry_run_server(port, t)) function that is ran once before visualization is started to speed up first fetch in the visualization. Provide custom function if your tree's children method takes a long time on first run.
- Also supports, the non-vector arguments of the vector-of-vectors `D3Tree` constructor, e.g. `title`, `init_expand`, `init_duration`, `svg_height`, `svg_node_size`.
"""
function D3Tree(node; detect_repeat::Bool=true, lazy_expand_after_depth::Integer=typemax(Int), kwargs...)

    t = D3Tree(Vector{Int}[]; kwargs...)

    if detect_repeat
        node_dict = Dict{Any,Int}()
        push_node!(t, node, lazy_expand_after_depth, node_dict)
    else
        push_node!(t, node, lazy_expand_after_depth)
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
- `text::Union{AbstractVector{<:AbstractString},Base.Callable}` - text to appear under each node, resp. a function `text(node)` to generate it.
- `tooltip::Union{AbstractVector{<:AbstractString},Base.Callable}` - text to appear when hovering over each node or a function.
- `style::Union{AbstractVector{<:AbstractString},Base.Callable}` - html style for each node or a function.
- `link_style::Union{AbstractVector{<:AbstractString},Base.Callable}` - html style for each link or a function.
- `title::String` - html title.
- `init_expand::Integer`: (default `0`) - levels to expand initially.
- `init_duration::Number`: (default `750`) - duration of the initial animation in ms.
- `svg_height::Number`: (default `600`) - height of the svg containing the tree in px.
- `svg_node_size::Tuple{Integer, Integer}`: (default: `(60, 60)`) - determines spacing of tree nodes by setting the [x, y] size of a bounding box around each visualized tree node.
- `on_click_display_depth::Integer`: (default: `1`) - how many tree levels are expanded with single click.
"""
function D3Tree(children::AbstractVector{<:AbstractVector}; kwargs...)
    kwd = Dict(kwargs)
    n = length(children)

    v_text, f_text = if haskey(kwd, :text)
        kw_text = kwd[:text]
        if kw_text isa Base.AbstractVector
            convert(Vector{String}, kw_text), text
        elseif kw_text isa Base.Callable
            fill("", n), kw_text
        else
            throw(ArgumentError("D3Tree kwwarg text must be an AbstractVector{<:AbstractString} or a Base.Callable"))
        end
    else
        collect(string(i) for i in 1:n), text
    end

    v_tooltip, f_tooltip = if haskey(kwd, :tooltip)
        kw_tooltip = kwd[:tooltip]
        if kw_tooltip isa Base.AbstractVector
            convert(Vector{String}, kw_tooltip), tooltip
        elseif kw_tooltip isa Base.Callable
            fill("", n), kw_tooltip
        else throw(ArgumentError("D3Tree kwwarg tooltip must be an AbstractVector{<:AbstractString} or a Base.Callable"))
        end
    else
        fill("", n), tooltip
    end

    v_style, f_style = if haskey(kwd, :style)
        kw_style = kwd[:style]
        if kw_style isa Base.AbstractVector
            convert(Vector{String}, kw_style), style
        elseif kw_style isa Base.Callable
            fill("", n), kw_style
        else throw(ArgumentError("D3Tree kwwarg style must be an AbstractVector{<:AbstractString} or a Base.Callable"))
        end
    else
        fill("", n), style
    end

    v_link_style, f_link_style = if haskey(kwd, :link_style)
        kw_link_style = kwd[:link_style]
        if kw_link_style isa Base.AbstractVector
            convert(Vector{String}, kw_link_style), link_style
        elseif kw_link_style isa Base.Callable
            fill("", n), kw_link_style
        else throw(ArgumentError("D3Tree kwwarg link_style must be an AbstractVector{<:AbstractString} or a Base.Callable"))
        end
    else
        fill("", n), link_style
    end

    frender = (text = f_text, tooltip = f_tooltip, style = f_style, link_style = f_link_style)

    return D3Tree(children,
        Dict(),
        v_text, v_tooltip, v_style, v_link_style,
        get(kwd, :title, "Julia D3Tree"),
        convert(Dict{Symbol,Any}, kwd),
        frender,
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

"""
DFS add node to the D3Tree structure
"""
function push_node!(t::D3Tree, node, lazy_expand_after_depth::Int, node_dict=nothing)
    if !(node_dict === nothing) && haskey(node_dict, node)
        return node_dict[node]
    end

    ind = length(t.children) + 1
    if !(node_dict === nothing)
        node_dict[node] = ind
    end

    push!(t.children, Int[])
    push!(t.text, t.frender.text(node))
    push!(t.tooltip, t.frender.tooltip(node))
    push!(t.style, t.frender.style(node))
    push!(t.link_style, t.frender.link_style(node))

    if lazy_expand_after_depth > 0
        for c in children(node)
            c_ind = push_node!(t, c, lazy_expand_after_depth - 1, node_dict)
            push!(t.children[ind], c_ind)
        end
    else
        t.unexpanded_children[ind] = node
    end
    return ind
end


"""
Subtree structure for use by the lazy fetching of data through the D3Trees server. Offset so that they can be easily entered into the `children` structure of D3Tree.
"""
struct D3OffsetSubtree
    root_children::Vector{Int}
    subtree::D3Tree
    root_id::Int

    function D3OffsetSubtree(root_id::Integer, subtree::D3Tree, offset::Integer)
        offset_subtree_children::Vector{Vector{Int}} = [[ind + offset for ind in child_inds] for child_inds in subtree.children]
        root_children = offset_subtree_children[1]
        offset_subtree = D3Tree(
            offset_subtree_children[2:end],
            Dict(ind + offset => node for (ind, node) in pairs(subtree.unexpanded_children)),
            subtree.text[2:end],
            subtree.tooltip[2:end],
            subtree.style[2:end],
            subtree.link_style[2:end],
            subtree.title,
            subtree.options,
            subtree.frender
        )
        new(root_children, offset_subtree, root_id)
    end
end

"""
Calculate missing children, for use with the D3Trees server for lazyly fetching data.
"""
function expand_node!(t::D3Tree, ind::Int, lazy_expand_after_depth::Int)
    # TODO: missing handling of caching of repeated nodes
    @assert haskey(t.unexpanded_children, ind) "Node at index $ind is already expanded!"
    node = pop!(t.unexpanded_children, ind)

    # TODO: also pass other options from t?
    subtree = D3Tree(node; lazy_expand_after_depth=lazy_expand_after_depth, t.options...)
    offset = length(t.children) - 1

    offset_subtree = D3OffsetSubtree(ind, subtree, offset)

    t.children[ind] = offset_subtree.root_children

    append!(t.children, offset_subtree.subtree.children)
    merge!(t.unexpanded_children, offset_subtree.subtree.unexpanded_children)
    append!(t.text, offset_subtree.subtree.text)
    append!(t.tooltip, offset_subtree.subtree.tooltip)
    append!(t.style, offset_subtree.subtree.style)
    append!(t.link_style, offset_subtree.subtree.link_style)

    return offset_subtree
end

include("server.jl")
include("show.jl")
include("displays.jl")
include("text.jl")

end # module
