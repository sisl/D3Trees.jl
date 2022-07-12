using HTTP
using Sockets
using Logging

debuglogger = ConsoleLogger(stderr, Logging.Debug)
global_logger(debuglogger)

ldroot = LimitedDepthTree()

t = D3Tree(ldroot, max_expand_depth=0)
unexpanded_ind=1
div_id = "treevisTestTree"
tree_data = Dict(div_id=>t)
HTTP.register!(D3Trees.TREE_ROUTER, "GET", "/api/d3trees/v1/test/{treediv}/{nodeid}", req -> D3Trees.handle_subtree_request(req, tree_data, 1))

D3Trees.reset_server()

try        
    # Valid request and response
    res200 = HTTP.get("http://localhost:$(D3Trees.PORT)/api/d3trees/v1/test/$div_id/$unexpanded_ind")
    @test res200.status==200
    @test D3Trees.CORS_RES_HEADERS[1] in res200.headers
    res_data = JSON.parse(String(res200.body))
    @test res_data["root_id"] == 0
    @test res_data["unexpanded_children"] == [1,2]
    
    # already expanded node
    try
        res410 = HTTP.get("http://localhost:$(D3Trees.PORT)/api/d3trees/v1/test/$div_id/$unexpanded_ind")
    catch e
        @test e isa HTTP.Exceptions.StatusError
        @test e.status == 410
    
        @test e.response.status==410
        @test D3Trees.CORS_RES_HEADERS[1] in e.response.headers
        @test String(e.response.body) == "Could not expand tree, likely because index $unexpanded_ind is already expanded!"
    end
    
    # bad tree name
    try
        res404 = HTTP.get("http://localhost:$(D3Trees.PORT)/api/d3trees/v1/test/badTreeName/$unexpanded_ind")
    catch e
        @test e isa HTTP.Exceptions.StatusError
        @test e.status == 404
    
        @test e.response.status==404
        @test D3Trees.CORS_RES_HEADERS[1] in e.response.headers
        @test String(e.response.body) == "Sever has no record of tree div badTreeName. Maybe it was cleared already?"
    end
    
    # Bad url
    try
        res404 = HTTP.get("http://localhost:$(D3Trees.PORT)/api/d3trees/v1/badpath")
    catch e
        @test e isa HTTP.Exceptions.StatusError
        @test e.status == 404
    
        @test e.response.status==404
        @test D3Trees.CORS_RES_HEADERS[1] in e.response.headers
    end
catch e
    throw(e)
finally
    close(D3Trees.SERVER[])
end