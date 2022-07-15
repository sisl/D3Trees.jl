using D3Trees, AbstractTrees

include(joinpath(dirname(dirname(pathof(D3Trees))), "test", "binary_abstract_trees.jl"))

ldroot = LimitedDepthTree()
t = D3Tree(ldroot, lazy_expand_after_depth=2, init_expand=2, lazy_subtree_depth=1)

io = IOBuffer()

show(io, "text/html", t)

html = String(take!(io))

write("./examples/dtree.html", html)