using HTTP
using Sockets
using Logging

#=
debuglogger = ConsoleLogger(stderr, Logging.Debug)
global_logger(debuglogger)
=#

ldroot = LimitedDepthTree()

t = D3Tree(ldroot, lazy_expand_after_depth=0)
unexpanded_ind = 1
div_id = "treevisTestTree"
tree_data = Dict(div_id => t)

port = D3Trees.DEFAULT_PORT + 42 # +42 in case a default server already running on machine
D3Trees.reset_server!(port)
HTTP.register!(D3Trees.SERVERS[port].router, "GET", "/api/d3trees/v1/test/{treediv}/{nodeid}", req -> D3Trees.handle_subtree_request(req, tree_data, 1))

try
    # Valid request and response
    res200 = HTTP.get("http://localhost:$(port)/api/d3trees/v1/test/$div_id/$unexpanded_ind")
    @test res200.status == 200
    @test D3Trees.CORS_RES_HEADERS[1] in res200.headers
    res_data = JSON.parse(String(res200.body))
    @test res_data["root_id"] == 0
    @test res_data["unexpanded_children"] == [1, 2]

    # already expanded node
    try
        res410 = HTTP.get("http://localhost:$(port)/api/d3trees/v1/test/$div_id/$unexpanded_ind")
    catch e
        @test e isa HTTP.Exceptions.StatusError
        @test e.status == 410

        @test e.response.status == 410
        @test D3Trees.CORS_RES_HEADERS[1] in e.response.headers
        @test String(e.response.body) == "Could not expand tree, likely because index $unexpanded_ind is already expanded! See server log for details."
    end

    # bad tree name
    try
        res404 = HTTP.get("http://localhost:$(port)/api/d3trees/v1/test/badTreeName/$unexpanded_ind")
    catch e
        @test e isa HTTP.Exceptions.StatusError
        @test e.status == 404

        @test e.response.status == 404
        @test D3Trees.CORS_RES_HEADERS[1] in e.response.headers
        @test String(e.response.body) == "Sever has no record of tree div badTreeName. Maybe it was cleared already?"
    end

    # Bad url
    try
        res404 = HTTP.get("http://localhost:$(port)/api/d3trees/v1/badpath")
    catch e
        @test e isa HTTP.Exceptions.StatusError
        @test e.status == 404

        @test e.response.status == 404
        @test D3Trees.CORS_RES_HEADERS[1] in e.response.headers
    end
catch e
    throw(e)
finally
    D3Trees.shutdown_server!()
end

@testset "multiple servers" begin
    ldroot = LimitedDepthTree()
    t1a = D3Tree(ldroot, lazy_expand_after_depth=0, port=port)
    t1b = D3Tree(ldroot, lazy_expand_after_depth=0, port=port)

    sroot = SparseTree()
    t2 = D3Tree(sroot, lazy_expand_after_depth=0, port=port + 1)

    # expand first node in first visualization on first server
    D3Trees.serve_tree!(D3Trees.SERVERS, t1a, div_id)
    @test HTTP.get("http://localhost:$(port)/$(D3Trees.API_PATH)/$div_id/$unexpanded_ind").status == 200

    # expand first node in secong visualization on first server
    div_id_b = div_id * "_b"
    D3Trees.serve_tree!(D3Trees.SERVERS, t1b, div_id_b)
    @test HTTP.get("http://localhost:$(port)/$(D3Trees.API_PATH)/$(div_id_b)/$unexpanded_ind").status == 200

    # expand first node of tree on the second server
    D3Trees.serve_tree!(D3Trees.SERVERS, t2, div_id)
    @test HTTP.get("http://localhost:$(port+1)/$(D3Trees.API_PATH)/$div_id/$unexpanded_ind").status == 200

    @test length(D3Trees.SERVERS) == 2
    @test length(D3Trees.SERVERS[port].tree_data) == 2
    @test length(D3Trees.SERVERS[port+1].tree_data) == 1

    D3Trees.shutdown_server!()
end

