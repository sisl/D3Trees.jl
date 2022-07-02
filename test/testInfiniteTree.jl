using D3Trees
using JSON
using Test
using Base64
using AbstractTrees

module TestTrees
using AbstractTrees
    include("binaryAbstractTrees.jl")
end


@testset "expand node" begin
    ldroot = TestTrees.LimitedDepthTree()
    t1 = D3Tree(ldroot, max_expand_depth=1)
    D3Trees.expand_node!(t1, 2, 1)
    D3Trees.expand_node!(t1, 3, 1)
    D3Trees.expand_node!(t1, 4, 1)
    D3Trees.expand_node!(t1, 5, 1)
    D3Trees.expand_node!(t1, 6, 1)
    D3Trees.expand_node!(t1, 7, 1)

    t2 = D3Tree(ldroot, max_expand_depth=1)
    D3Trees.expand_node!(t2, 2, 2)
    D3Trees.expand_node!(t2, 3, 2)

    t3 = D3Tree(ldroot, max_expand_depth=3)

    # The trees are grown differently, so indeces can be ordered differently
    @test length(t1.children) == length(t2.children) == length(t3.children)
    @test sort(t1.text) == sort(t2.text) == sort(t3.text)
    @test sort(t1.tooltip) == sort(t2.tooltip) == sort(t2.tooltip)
    @test sort(t1.style) == sort(t2.style) == sort(t2.style)
    @test sort(t1.link_style) == sort(t2.link_style) == sort(t2.link_style)
    t1_unexplored_children = sort(collect(values(t1.unexpanded_children)); lt=(x, y) -> x.id < y.id)
    t2_unexplored_children = sort(collect(values(t2.unexpanded_children)); lt=(x, y) -> x.id < y.id)
    t3_unexplored_children = sort(collect(values(t3.unexpanded_children)); lt=(x, y) -> x.id < y.id)
    @test t1_unexplored_children == t2_unexplored_children == t3_unexplored_children

    # But they should represent the same tree
    io = IOBuffer()
    show(IOContext(io, :limit => true, :displaysize => (10, 10)), "text/plain", t1)
    s1 = String(take!(io))

    io = IOBuffer()
    show(IOContext(io, :limit => true, :displaysize => (10, 10)), "text/plain", t2)
    s2 = String(take!(io))

    @test s1 == s2
end

