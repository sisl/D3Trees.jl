"""
Binary tree node. Must have field id.
"""
abstract type BTNode end

bt_depth(id::Int) = floor(UInt, log2(id))
bt_children_ids(id::Int) = [2 * id, 2 * id + 1]
bt_depth(n::BTNode) = bt_depth(n.id)
Base.show(io::IO, n::BTNode) = print(io, "$(n.id) (d=$(bt_depth(n))) -> $(getfield.(AbstractTrees.children(n), :id))")


"""
    LimitedDepthTree(id, max_leaf_depth)

Create binary tree rooted at index with leave depth specified by the `max_leaf_depth` parameter.
The AbstractTrees.children method does not expand the tree beyond the `max_leaf_depth`.
Maximum `max_leaf_depth` is typemax(Int)
"""

struct LimitedDepthTree <: BTNode
    id::Int
    max_leaf_depth::Int

    function LimitedDepthTree(id, leaf_depth)
        @assert id > 0 "All notes must have id > 0, root has 1."
        @assert leaf_depth >= 0
        new(id, leaf_depth)
    end
end

LimitedDepthTree(; root_id=1, max_leaf_depth=typemax(Int)) = LimitedDepthTree(root_id, max_leaf_depth)
expand(n::LimitedDepthTree) = bt_depth(n) < n.max_leaf_depth
AbstractTrees.children(n::LimitedDepthTree) = expand(n) ? LimitedDepthTree.(bt_children_ids(n.id), n.max_leaf_depth) : LimitedDepthTree[]


"""
    SparseTree(id, leaf_depth)

Create binary tree rooted at index. 
On every level of odd depth, the odd-numbered node is a leaf.

E.g.:
Nodes:            Depth:
         1           0
     2        3      1
  4    5             2
 8 9 10 11           3
 """

struct SparseTree <: BTNode
    id::Int

    function SparseTree(id)
        @assert id > 0 "All notes must have id > 0, root has 1."
        new(id)
    end
end
SparseTree() = SparseTree(1)

function AbstractTrees.children(n::SparseTree)
    if bt_depth(n) % 2 == 0
        SparseTree.(bt_children_ids(n.id))
    else
        n.id % 2 == 0 ? SparseTree.(bt_children_ids(n.id)) : SparseTree[]
    end
end