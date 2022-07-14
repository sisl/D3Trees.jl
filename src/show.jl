"""
Convert datastructure to json, shift indeces to zero-indexing for use in javascript
"""
function JSON.json(t::D3Tree)
    data = Dict(key => getfield(t, key) for key ∈ fieldnames(D3Tree))
    data[:children] = [Int[ind - 1 for ind ∈ list] for list ∈ data[:children]]
    data[:unexpanded_children] = Int[k - 1 for k ∈ keys(data[:unexpanded_children])]
    return json(data)
end

"""
Convert datastructure to json, shift indeces to zero-indexing for use in javascript
"""
function JSON.json(st::D3OffsetSubtree)
    data = Dict(key => getfield(st.subtree, key) for key ∈ fieldnames(D3Tree))
    
    data[:root_children] = Int[ind - 1 for ind ∈ st.root_children]
    data[:root_id] = st.root_id - 1

    data[:children] = [Int[ind - 1 for ind ∈ list] for list ∈ data[:children]]
    data[:unexpanded_children] = Int[k - 1 for k ∈ keys(data[:unexpanded_children])]
    return json(data)
end

function Base.show(f::IO, m::MIME"text/html", t::D3Tree)

    tree_json = json(t)
    root_id = 1
    css = read(joinpath(dirname(@__FILE__()), "..", "css", "tree_vis.css"), String)
    js = read(joinpath(dirname(@__FILE__()), "..", "js", "tree_vis.js"), String)
    div = "treevis$(randstring())"

    try
        # do not bother with server if tree has no unexpanded nodes.
        if length(t.unexpanded_children) > 0 
            # if server has not been started yet, do so.
            if !isassigned(SERVER) 
                reset_server()
                # speedup first-click response in the visualization
                get(t.options, :dry_run_lazy_vizualization, true) ? dry_run_server(t) : nothing
            end
            
            TREE_DATA[][div]=t
            lazy_subtree_depth = get(t.options, :lazy_subtree_depth, DEFAULT_LAZY_SUBTREE_DEPTH)
            HTTP.register!(TREE_ROUTER, "GET", "/api/d3trees/v1/tree/{treediv}/{nodeid}", req -> handle_subtree_request(req, TREE_DATA[], lazy_subtree_depth))
        end


        html_string = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <title>$(t.title)</title>
            </head>
            <body>
            <div id="$div">
            <style>
                $css
            </style>
            <script>
            (function(){
                var treeData = $tree_json;
                var rootID = $root_id-1;
                var div = "$div";
                var initExpand = $(get(t.options, :init_expand, 0));
                var initDuration = $(get(t.options, :init_duration, 750));
                var svgHeight = $(get(t.options, :svg_height, 600));
                var tree_url = "$TREE_URL";
                $js
                })();
            </script>
            <p class="d3twarn">
            Attempting to display the tree. If the tree is large, this may take some time.
            </p>
            <p class="d3twarn">
            Note: D3Trees.jl requires an internet connection. If no tree appears, please check your connection. To help fix this, please see <a href="https://github.com/sisl/D3Trees.jl/issues/10">this issue</a>. You may also diagnose errors with the javascript console (Ctrl-Shift-J in chrome).
            </p>
            </div>
            </body>
            </html>
        """

        println(f,html_string)
    catch e
        # When running in Jupyter, error in show is ignored and another non-failing method is used instead 
        # (See https://github.com/JuliaLang/IJulia.jl/issues/1041)
        # The logging below makes sure the error is noticed
        @error "Show error:" exception=(e,catch_backtrace())
        rethrow(e)
    end
end

# fallback when only the repl is available
function Base.show(io::IO, m::MIME"text/plain", t::D3Tree)
    # TODO: handle tree expand depth here
    show(io, m, D3TreeView(D3TreeNode(t, 1), get(t.options, :init_expanded, false) ? typemax(Int) : 3))
end
Base.show(io::IO, m::MIME"text/plain", v::D3TreeView) = shownode(io, v.root, v.depth, "", "")
