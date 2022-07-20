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

cors404(::HTTP.Request) = HTTP.Response(404, CORS_RES_HEADERS, "")
cors405(::HTTP.Request) = HTTP.Response(405, CORS_RES_HEADERS, "")

const HOST = Sockets.localhost

struct D3TreeServer
    server::HTTP.Servers.Server
    router::HTTP.Router
    tree_data::Dict{String,D3Tree}
end
HTTP.close(d3s::D3TreeServer) = close(d3s.server)

const SERVERS = Dict{Int64,D3TreeServer}()



"""
    D3Trees.reset_server!(port)

Restart D3Trees server on given port and remove the associated tree_data holding the unexpanded nodes. 
Use it to get rid of past visualizations that are still kept in memory.
"""

function reset_server!(port)
    @info "(Re)setting D3Trees server at $HOST:$port"

    # Kill server on given port if runnning
    if haskey(SERVERS, port)
        shutdown_server!(port)
    end

    # start new server on given port
    router = HTTP.Router(cors404, cors405)
    server = HTTP.serve!(router |> cors_middleware |> logging_middleware, HOST, port)
    tree_data = Dict{String,D3Tree}()
    d3s = D3TreeServer(server, router, tree_data)
    SERVERS[port] = d3s
    return d3s
end

"""
    D3Trees.shutdown_server!(port)
    D3Trees.shutdown_server!()

Shutdown D3Trees server (all servers if port is not specified) and remove associated tree data.
"""
function shutdown_server!(port)
    d3s = SERVERS[port]
    isopen(d3s.server) ? close(d3s) : nothing
    @assert istaskdone(d3s.server.task)
    delete!(SERVERS, port)
end
shutdown_server!() = [shutdown_server!(port) for port in keys(SERVERS)]


"""
logging_middleware logs the request before passing it on to the tree router and request handler and then logs the returned response.
"""
function logging_middleware(handler)
    # Middleware functions return *Handler* functions
    return function (req::HTTP.Request)
        @debug "Incoming server request:\n$req"
        res = handler(req)
        @debug "Server reponds:\n$res"
        return res
    end
end

"""
cors_middleware: handles preflight request with the OPTIONS flag
If a request was recieved with the correct headers, then a response will be 
sent back with a 200 code, if the correct headers were not specified in the request,
then a CORS error will be recieved on the client side
Since each request passes throught the CORS Handler, then if the request is 
not a preflight request, it will simply go to the rest of the layers to be passed to the
correct service function.
"""
function cors_middleware(handler)
    return function (req::HTTP.Request)
        if HTTP.hasheader(req, "OPTIONS")
            return HTTP.Response(200, CORS_OPT_HEADERS)
        else
            return handler(req)
        end
    end
end

function process_node_expand_request(tree_data::Dict{String,D3Tree}, div_id::String, subtree_root_id::Integer, depth::Integer)
    if haskey(tree_data, div_id)
        tree = tree_data[div_id]
        try
            subtree = expand_node!(tree, subtree_root_id, depth)
            return HTTP.Response(200, CORS_RES_HEADERS, JSON.json(subtree))
        catch e
            @error "[TREE] Could not expand tree!\n$(serror(e))"
            # rethrow(e)
            return HTTP.Response(410, CORS_RES_HEADERS, "Could not expand tree, likely because index $subtree_root_id is already expanded! See server log for details.")
        end
    else
        @error "[SERVER] No record of tree" div_id
        # throw(KeyError(div_id))
        return HTTP.Response(404, CORS_RES_HEADERS, "Sever has no record of tree div $(div_id). Maybe it was cleared already?")
    end
end

function handle_subtree_request(req::HTTP.Request, tree_data::Dict{String,D3Tree}, lazy_subtree_depth::Integer)
    tree_div = HTTP.getparams(req)["treediv"]
    node_id = parse(Int, HTTP.getparams(req)["nodeid"])
    @debug "Request for tree $tree_div - Node: $node_id\n$req"
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
function dry_run_server(port, tree::D3Tree)
    # t = deepcopy(tree)
    # unexpanded_ind = [keys(t.unexpanded_children)...][1]

    n = DryRunTree()
    t = D3Tree(n, lazy_expand_after_depth=0)
    unexpanded_ind = 1

    div_id = "treevisDryRun"
    tree_data = Dict(div_id => t)
    HTTP.register!(SERVERS[port].router, "GET", "/api/d3trees/v1/dryrun/{treediv}/{nodeid}", req -> handle_subtree_request(req, tree_data, 1))
    HTTP.get("http://localhost:$(port)/api/d3trees/v1/dryrun/$div_id/$unexpanded_ind")
end


const DEFAULT_LAZY_SUBTREE_DEPTH = 2
const DEFAULT_PORT = 16370
const API_PATH = "api/d3trees/v1/tree"

"""
    Start serving tree from existing or new server on some port. Returns port for the server.
"""
function serve_tree!(servers::Dict{<:Integer,D3TreeServer}, t::D3Tree, div::String)
    port = get(t.options, :port, DEFAULT_PORT)
    lazy_subtree_depth = get(t.options, :lazy_subtree_depth, DEFAULT_LAZY_SUBTREE_DEPTH)

    # if server on this port is not yet running, start it.
    if !haskey(servers, port)
        d3server = reset_server!(port)
        # speedup first-click response in the visualization
        get(t.options, :dry_run_lazy_vizualization, t -> dry_run_server(port, t))(t)
    else
        d3server = servers[port]
    end

    d3server.tree_data[div] = t
    HTTP.register!(servers[port].router, "GET", "/$API_PATH/{treediv}/{nodeid}", req -> handle_subtree_request(req, d3server.tree_data, lazy_subtree_depth))
    return port
end

"""
    serror(error::Exception) -> String
    
Get error and stacktrace as String, e.g. for use in warning. 
Useful in Jypyter notebooks where error messages are not displayed correctly (https://github.com/JuliaLang/IJulia.jl/issues/1043)

# Example
```julia
julia> try
           a=b
       catch e
           @warn "Oh no, exception:\n \$(serror(e))"
       end
┌ Warning: Oh no, exception:
│  UndefVarError: b not defined
│ 13-element Vector{Base.StackTraces.StackFrame}:
│  top-level scope at REPL[7]:2
│  eval at boot.jl:373 [inlined]
│  eval_user_input(ast::Any, backend::REPL.REPLBackend) at REPL.jl:150
│  repl_backend_loop(backend::REPL.REPLBackend) at REPL.jl:246
│  start_repl_backend(backend::REPL.REPLBackend, consumer::Any) at REPL.jl:231
│  run_repl(repl::REPL.AbstractREPL, consumer::Any; backend_on_current_task::Bool) at REPL.jl:364
│  run_repl(repl::REPL.AbstractREPL, consumer::Any) at REPL.jl:351
│  (::Base.var"#930#932"{Bool, Bool, Bool})(REPL::Module) at client.jl:394
│  #invokelatest#2 at essentials.jl:716 [inlined]
│  invokelatest at essentials.jl:714 [inlined]
│  run_main_repl(interactive::Bool, quiet::Bool, banner::Bool, history_file::Bool, color_set::Bool) at client.jl:379
│  exec_options(opts::Base.JLOptions) at client.jl:309
│  _start() at client.jl:495
└ @ Main REPL[7]:4
```
"""
function serror(error::Exception)
    error_msg = sprint(showerror, error)
    st = sprint((io, v) -> show(io, "text/plain", v), stacktrace(catch_backtrace()))
    return "$error_msg\n$st"
end