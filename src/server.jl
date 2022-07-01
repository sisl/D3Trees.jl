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

function process_node_expand_request(tree_data::Dict{String, D3Tree}, request::Dict, depth::Integer)
    if haskey(request, "tree_div_id") && haskey(request, "subtree_root_id")
        div_id = request["tree_div_id"]
        subtree_root_id = request["subtree_root_id"]

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
    else
        @error "[SERVER] Received unrecognized request" request
        throw(ErrorException("Unexpected request"))
    end
end

function run_server(host, port, tree_data; verbose=false)
    server = HTTP.WebSockets.listen!(host, port; verbose=verbose) do ws
        for msg in ws
            let request, response
                try
                    request = JSON.parse(msg)
                catch e
                    @error "[SERVER] Request could not be parsed as JSON: '$msg'"
                    continue
                end
                try
                    response = process_node_expand_request(tree_data, request, 2)
                catch e
                    @error "[SERVER] Trouble processing request:" (e, catch_backtrace())
                    continue
                end
                # TODO: If there was an error, I should send a message to the GUI to let the user know
                send(ws, response)
            end
        end
    end
    return server
end