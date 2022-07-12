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
cors404(::HTTP.Request) = HTTP.Response(404, CORS_RES_HEADERS, "")
cors405(::HTTP.Request) = HTTP.Response(405, CORS_RES_HEADERS, "")
const TREE_ROUTER = HTTP.Router(cors404, cors405)
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
serializes it as json and sends back a success response code.
=#
function JSONMiddleware(handler)
    # Middleware functions return *Handler* functions
    return function(req::HTTP.Request)
        @info "Incoming server request:\n$req"
        ret = handler(req)
        # 404 and 405 handlers will return HTTP.Response already
        if ret isa HTTP.Response
            res = ret
        else
            res = HTTP.Response(200, CORS_RES_HEADERS, ret === nothing ? "" : JSON.json(ret))
        end
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
            return subtree
        catch e
            @error "[TREE] Could not expand tree!\n$(serror(e))"
            # rethrow(e)
            return HTTP.Response(410, CORS_RES_HEADERS, "Could not expand tree, likely because index $subtree_root_id is already expanded!")
        end
    else
        @error "[SERVER] No record of tree" div_id
        # throw(KeyError(div_id))
        return HTTP.Response(404, CORS_RES_HEADERS, "Sever has no record of tree div $(div_id). Maybe it was cleared already?")
    end
end

function handle_subtree_request(req::HTTP.Request, tree_data::Dict{String, D3Tree}, lazy_subtree_depth::Integer)
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

"""
    serror(error::Exception) -> String
Get error and stacktrace as String, e.g. for use in warning. 
Useful in Jypyter notebooks where error messages are not displayed correctly (https://github.com/JuliaLang/IJulia.jl/issues/1043)
Example:
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
    st = sprint((io,v) -> show(io, "text/plain", v), stacktrace(catch_backtrace()))
    return "$error_msg\n$st"
end