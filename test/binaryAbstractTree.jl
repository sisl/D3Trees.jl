"""
    BTNode(id, leaf_depth)

Binary tree node with leave depth specified by the `leaf_depth` parameter.
The AbstractTrees.children method does not expand the tree beyond the `leaf_depth`.
Maximum `leaf_depth` is typemax(Int64)
"""
struct BTNode
    id::Int64
    leaf_depth::Int64

    function BTNode(id, leaf_depth)
        @assert id>0 "All notes must have id > 0, root has 1."
        @assert leaf_depth>=0
        new(id, leaf_depth)
    end
end

function BTNode(id; leaf_depth=typemax(Int64))
    BTNode(id, leaf_depth)
end

depth(id::Int64) = floor(Int64, log2(id))
depth(n::BTNode) = depth(n.id)
children_ids(id::Int64) = [2*id, 2*id+1]
expand(n::BTNode) = depth(n) < n.leaf_depth
AbstractTrees.children(n::BTNode) = expand(n) ? BTNode.(children_ids(n.id), n.leaf_depth) : BTNode[]
Base.show(io::IO, n::BTNode) = print(io, "$(n.id) (d=$(depth(n))) -> $(expand(n) ? children_ids(n.id) : [])")