"""
Server is based on CORS example from https://github.com/JuliaWeb/HTTP.jl/blob/170725b1db2d59a0699ad03712bc59175a635010/docs/examples/cors_server.jl
"""

# CORS "preflight" OPTIONS headers that show what kinds of complex requests are allowed to API
const CORS_OPT_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "GET, OPTIONS"
]

# CORS respoonse headers (according to https://cors-errors.info/faq)
const CORS_RES_HEADERS = ["Access-Control-Allow-Origin" => "*"]

TREE_DATA = Ref{Dict{String, D3Tree}}()
const PORT = 16370 # Randomly chosen
const TREE_URL = "http://localhost:$(PORT)/api/d3trees/v1/tree/"
const HOST = Sockets.localhost
SERVER = Ref{HTTP.Servers.Server}()
const TREE_ROUTER = HTTP.Router(HTTP.Response(404, CORS_RES_HEADERS, ""), HTTP.Response(405, CORS_RES_HEADERS, ""), HTTP.Node())
const DEFAULT_LAZY_SUBTREE_DEPTH = 2

"""
    reset_server()

Restart D3Trees server and resets the TREE_DATA. 
Use it to get rid of past visualizations that are still kept in memory.
"""
function reset_server()
    @info "(Re)setting D3Trees server."
    TREE_DATA[] = Dict{String, D3Tree}()
    if isassigned(SERVER) && isopen(SERVER[])
        close(SERVER[])
    end    
    SERVER[] = HTTP.serve!(TREE_ROUTER |> JSONMiddleware |> CorsMiddleware, HOST, PORT)
end


#= 
JSONMiddleware recieves the body of the response from the other service funtions 
and sends back a success response code.
=#
function JSONMiddleware(handler)
    # Middleware functions return *Handler* functions
    return function(req::HTTP.Request)
        @info "Incoming server request:\n$req"
        ret = handler(req)
        res = HTTP.Response(200, CORS_RES_HEADERS, ret === nothing ? "" : JSON.json(ret))
        @info "Server reponds:\n$res"
        return res
    end
end

#= CorsMiddleware: handles preflight request with the OPTIONS flag
If a request was recieved with the correct headers, then a response will be 
sent back with a 200 code, if the correct headers were not specified in the request,
then a CORS error will be recieved on the client side
Since each request passes throught the CORS Handler, then if the request is 
not a preflight request, it will simply go to the JSONMiddleware to be passed to the
correct service function =#
function CorsMiddleware(handler)
    return function(req::HTTP.Request)
        if HTTP.hasheader(req, "OPTIONS")
            return HTTP.Response(200, CORS_OPT_HEADERS)
        else 
            return handler(req)
        end
    end
end

function process_node_expand_request(tree_data::Dict{String, D3Tree}, div_id::String, subtree_root_id::Integer, depth::Integer)
    if haskey(tree_data, div_id)
        tree = tree_data[div_id]
        try
            subtree = D3Trees.expand_node!(tree, subtree_root_id, depth)
            # response = JSON.json(subtree)
            return subtree
        catch e
            @error "[TREE] Could not expand tree:"
            rethrow(e)
        end
    else
        @error "[SERVER] No record of tree" div_id
        throw(KeyError(div_id))
    end
end

function handle_subtree_request(req::HTTP.Messages.Message, tree_data::Dict{String, D3Tree}, lazy_subtree_depth::Integer)
    tree_div = HTTP.getparams(req)["treediv"]
    node_id = parse(Int, HTTP.getparams(req)["nodeid"])
    @info "Request for tree $tree_div - Node: $node_id\n$req"
    return process_node_expand_request(tree_data, tree_div, node_id, lazy_subtree_depth)
end


# SERVER DRY RUN
struct DryRunTree end
AbstractTrees.children(t::DryRunTree) = [1,]
"""
Runs api request against a simple tree. When ran before rendering first visualization, 
it leads to faster visualization responses on first click. This helps prevent 
errors caused by trying to fetching the same resource twice.
"""
function dry_run_server(t_orig::D3Tree)
    n = DryRunTree()
    t = D3Tree(n, max_expand_depth=0)
    unexpanded_ind=1
    
    # t = deepcopy(t_orig)
    # unexpanded_ind = [keys(t.unexpanded_children)...][1]

    div_id = "treevisDryRun"
    tree_data = Dict(div_id=>t)
    HTTP.register!(TREE_ROUTER, "GET", "/api/d3trees/v1/dryrun/{treediv}/{nodeid}", req -> handle_subtree_request(req, tree_data, 1))
    HTTP.get("http://localhost:$(PORT)/api/d3trees/v1/dryrun/$div_id/$unexpanded_ind")
end