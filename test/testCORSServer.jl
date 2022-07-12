using D3Trees
using JSON
using Test
using Base64
using AbstractTrees

using HTTP
using Sockets

module TestTrees
    using AbstractTrees
    include("binaryAbstractTrees.jl")
end

ldroot = TestTrees.LimitedDepthTree()

t = D3Tree(ldroot, max_expand_depth=0)
unexpanded_ind=1
div_id = "treevisTestTree"
tree_data = Dict(div_id=>t)
HTTP.register!(D3Trees.TREE_ROUTER, "GET", "/api/d3trees/v1/dryrun/{treediv}/{nodeid}", req -> D3Trees.handle_subtree_request(req, tree_data, 1))

D3Trees.reset_server()
res = HTTP.get("http://localhost:$(D3Trees.PORT)/api/d3trees/v1/dryrun/$div_id/$unexpanded_ind")

@test res.status==200

s = String(res.body)
res_data = JSON.parse(s)

close(D3Trees.SERVER[])

@testset "D3Trees server" begin
    try
        D3Trees.reset_server()
        res = HTTP.get("http://localhost:$(D3Trees.PORT)/api/d3trees/v1/dryrun/$div_id/$unexpanded_ind")

    catch e
        throw(e)
    finally
        close(D3Trees.SERVER[])
    end
end
