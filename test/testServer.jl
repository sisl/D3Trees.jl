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

@testset "Test server" begin

ldroot = TestTrees.LimitedDepthTree()

# Using WS demo from https://github.dev/JuliaWeb/HTTP.jl/tree/master/src

t = D3Tree(ldroot, max_expand_depth=2)

port = 36984

tree_data = Dict{String, D3Tree}()
DIV_ID = "treevis123"
tree_data[DIV_ID] = t 

# Start the server async
server = D3Trees.run_server(Sockets.localhost, port, tree_data; verbose=true)

try
    # close(server)
    # throw(Exception("Oh no"))
    
    request = "{\"tree_div_id\":\"$DIV_ID\",\"subtree_root_id\":3}"
    response = HTTP.post("http://$(Sockets.localhost):$port"; body=request, verbose=1)
    @test length(t.unexpanded_children)==3+4
    r = JSON.parse(String(response.body))

    # "+1": responses are converted to javascript 0-based indexing
    @test r["root_id"]+1==3 
    @test setdiff(Set(keys(t.unexpanded_children)), [v+1 for v in r["unexpanded_children"]]) == Set([4,6,7])
catch e
    @info "Error while testing" (e, catch_backtrace())
finally
    @info "Killing server"
    close(server)
end
end
