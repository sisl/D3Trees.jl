# import Pkg;
# Pkg.activate("test");
# using Debugger
using D3Trees
using JSON
using Test
# using NBInclude
using Base64
using AbstractTrees
using HTTP
using Sockets

module TestTrees
    using AbstractTrees
    include("binaryAbstractTrees.jl")
end

ldroot = TestTrees.LimitedDepthTree()

# Using WS demo from https://github.dev/JuliaWeb/HTTP.jl/tree/master/src

t = D3Tree(ldroot, max_expand_depth=2)

port = 36984

TREE_DATA = Dict{String, D3Tree}()
DIV_ID = "treevis123"
TREE_DATA[DIV_ID] = t 

function handle_subtree_request(req::HTTP.Request)
    tree_div = HTTP.getparams(req)["treediv"]
    node_id = parse(Int, HTTP.getparams(req)["nodeid"])
    @info "Handling $tree_div - $node_id req: $req"
    return D3Trees.process_node_expand_request(TREE_DATA, tree_div, node_id, 2)
end

function handle_test(req::HTTP.Request)
    val = parse(Int, HTTP.getparams(req)["val"])
    val2 = parse(Int, HTTP.getparams(req)["val2"])
    @info "Test OK, $val - $val2 req: $req"
    return "Test OK, $val -  $val2 req: $req"
end

# add an additional endpoint for user creation
const TREE_ROUTER = HTTP.Router()
HTTP.register!(TREE_ROUTER, "GET", "/api/d3trees/v1/tree/{treediv}/{nodeid}", handle_subtree_request)
HTTP.register!(TREE_ROUTER, "GET", "/api/d3trees/v1/test/{val}/{val2}", handle_test)

server = HTTP.serve!(TREE_ROUTER |> D3Trees.JSONMiddleware |> D3Trees.CorsMiddleware, Sockets.localhost, port)
# close(server)


t.unexpanded_children
node_id = 3
v = HTTP.get("http://localhost:$port/api/d3trees/v1/tree/$(DIV_ID)/$(node_id)")

a=5
v = HTTP.get("http://localhost:$port/api/d3trees/v1/test/$a/6")


# Start the server async
# server = D3Trees.run_server(Sockets.localhost, port, TREE_DATA; verbose=true)

# close(server)
# throw(Exception("Oh no"))

# request = "{\"tree_div_id\":\"$DIV_ID\",\"subtree_root_id\":3}"
# response = HTTP.post("http://$(Sockets.localhost):$port"; body=request, verbose=1)
# @test length(t.unexpanded_children)==3+4
# r = JSON.parse(String(response.body))

# # "+1": responses are converted to javascript 0-based indexing
# @test r["root_id"]+1==3 
# @test setdiff(Set(keys(t.unexpanded_children)), [v+1 for v in r["unexpanded_children"]]) == Set([4,6,7])

# @info "Error while testing" (e, catch_backtrace())

# @info "Killing server"
# close(server)

