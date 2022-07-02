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


"""
Using CORS example from https://github.com/JuliaWeb/HTTP.jl/blob/170725b1db2d59a0699ad03712bc59175a635010/docs/examples/cors_server.jl
"""

# CORS headers that show what kinds of complex requests are allowed to API
const CORS_OPT_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

const CORS_RES_HEADERS = ["Access-Control-Allow-Origin" => "*"]
const TREE_DATA = Dict{String, D3Tree}()
const PORT = 16370
const HOST = Sockets.localhost
SERVER = Ref{HTTP.Servers.Server}()

#= 
JSONMiddleware minimizes code by automatically converting the request body
to JSON to pass to the other service functions automatically. JSONMiddleware
recieves the body of the response from the other service funtions and sends
back a success response code
=#
function JSONMiddleware(handler)
    # Middleware functions return *Handler* functions
    return function(req::HTTP.Request)
        # first check if there's any request body
        # if isempty(req.body)
        #     # we slightly change the Handler interface here because we know
        #     # our handler methods will either return a subtree instance
        #     ret = handler(req)
        # else
        #     # replace request body with parsed Animal instance

        #     # req.body = JSON3.read(req.body, Animal)
        #     # req.body = JSON.parse(String(req.body))
        #     ret = handler(req)
        # end
        ret = handler(req)
        @info req
        # return a Response, serializing any Animal as json string
        res = HTTP.Response(200, CORS_RES_HEADERS, ret === nothing ? "" : JSON.json(ret))
        @info res
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
            response = JSON.json(subtree)
            return response
        catch e
            @error "[TREE] Could not expand tree:"
            rethrow(e)
        end
    else
        @error "[SERVER] No record of tree" div_id
        throw(KeyError(div_id))
    end
end

function handle_subtree_request(req::HTTP.Request)
    tree_div = HTTP.getparams(req)["treediv"]
    node_id = parse(Int, HTTP.getparams(req)["nodeid"])
    @info "Handling $tree_div - $node_id req: $req"
    return D3Trees.process_node_expand_request(TREE_DATA, tree_div, node_id, 2)
end

# const TREE_ROUTER = HTTP.Router()
# HTTP.register!(TREE_ROUTER, "GET", "/api/d3trees/v1/{tree_div}/{node_id}", handle_request)

# server = HTTP.serve!(TREE_ROUTER |> JSONMiddleware |> CorsMiddleware, Sockets.localhost, 8080)


# function run_server(host, port, tree_data; verbose=false)
#     server = HTTP.serve!(host, port; verbose=verbose) do request
#         let payload, response
#             try
#                 payload = JSON.parse(String(request.body))
#             catch e
#                 @error "[SERVER] Request body could not be parsed as JSON: '$(request.body)'"
#                 throw(e)
#             end
#             try
#                 response = process_node_expand_request(tree_data, payload, 2)
#             catch e
#                 @error "[SERVER] Trouble processing request:" (e, catch_backtrace())
#                 throw(e)
#             end
#             # TODO: If there was an error, I should send a message to the GUI to let the user know
#             headers = [
#                 "Access-Control-Allow-Origin"=>"*"
#             ]
#             CORS_HEADERS = [
#                 "Access-Control-Allow-Origin" => "*",
#                 "Access-Control-Allow-Headers" => "*",
#                 "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
#             ]
#             return HTTP.Response(200, CORS_HEADERS, response)
#         end
#     end
#     return server
# end