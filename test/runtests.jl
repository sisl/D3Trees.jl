using D3Trees
using JSON
using Test
using NBInclude
using Base64
using AbstractTrees

include("binary_abstract_trees.jl")

@testset "simple tree" begin
    children = [[2,3], [], [4], []]
    text = ["one\n(second line)", "2", "III", "four"]
    style = ["", "fill:red", "r:14", "opacity:0.7"]
    link_style = ["", "stroke:blue", "", "stroke-width:10px"]
    tooltip = ["pops", "up", "on", "hover"]
    t1 = D3Tree(children,
            text=text,
            style=style,
            tooltip=tooltip,
            link_style=link_style)

    @show json(t1)

    stringmime(MIME("text/html"), t1)

    t2 = D3Tree(children,
                text=text,
                style=style,
                tooltip=tooltip,
                link_style=link_style,
                init_expand=1000,
                init_duration=5000,
                svg_height=300
            )

    # inchrome(t1)
    # inbrowser(t1, "firefox")
    # inchrome(t2)
    # inbrowser(t2, "firefox")

    @show D3Trees.children(D3TreeNode(t1, 1))
    show(stdout, MIME("text/plain"), t1)

    @nbinclude("../examples/hello.ipynb")

    n = 1_000_000
    println("generating $n children")
    @time begin
        children = [[i+1] for i in 1:n-1]
        push!(children, [])
    end

    println("creating tree object")
    @time t = D3Tree(children)

    println("html string")
    @time stringmime(MIME("text/html"), t)

    println("AbstractTrees constructor")
    @time t3 = D3Tree(t1)
    @time t4 = D3Tree(t1, detect_repeat=false)
    @test t3.text == t1.text
    @test t3.tooltip == t1.tooltip
    @test t3.style == t1.style
    @test t3.link_style == t1.link_style

    inbrowser(D3Tree([[2],[]]), `ls`)
end

@testset "lazy loading tree" begin
    println("Limited depth abstract tree")
    ldroot = LimitedDepthTree()
    t1 = D3Tree(ldroot, lazy_expand_after_depth=0, init_expand=1, lazy_subtree_depth=1)
    D3Trees.expand_node!(t1, 1, 1)
    @test t1.children == Vector{Int64}[[2,3],[],[]]
    @test 2 in keys(t1.unexpanded_children)
    @test 3 in keys(t1.unexpanded_children)
    @test t1.options[:init_expand]==1
    @test t1.options[:lazy_subtree_depth]==1

    println("Notebook")
    @nbinclude("../examples/lazy_load_deep_trees.ipynb")
end

@testset "tree expansion" begin
    include("test_tree_expansion.jl")
end

@testset "server" begin
    include("test_server.jl")
end
