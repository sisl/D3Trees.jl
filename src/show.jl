"""
Convert datastructure to json, shift indeces to zero-indexing for use in javascript
"""
function JSON.json(t::D3Tree)
    fields = (:children, :unexpanded_children, :text, :tooltip, :style, :link_style, :title)
    data = Dict(key => getfield(t, key) for key ∈ fields)
    data[:children] = [Int[ind - 1 for ind ∈ list] for list ∈ data[:children]]
    data[:unexpanded_children] = Int[k - 1 for k ∈ keys(data[:unexpanded_children])]
    return json(data)
end

"""
Convert datastructure to json, shift indeces to zero-indexing for use in javascript
"""
function JSON.json(st::D3OffsetSubtree)
    fields = (:children, :unexpanded_children, :text, :tooltip, :style, :link_style, :title)
    data = Dict(key => getfield(st.subtree, key) for key ∈ fields)
    
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
    tree_url="" #Only set when running the server

    try
        # do not run the server if the tree has no unexpanded nodes.
        if length(t.unexpanded_children) > 0 
            port = serve_tree!(SERVERS, t, div)
            tree_url = "http://$HOST:$(port)/$API_PATH/"
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
                var svgNodeSize = $(collect(get(t.options, :svg_node_size, (60, 60))));
                var on_click_display_depth = $(get(t.options, :on_click_display_depth, 1));
                var tree_url = "$tree_url";
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
        throw(e)
    end
end

# fallback when only the repl is available
function Base.show(io::IO, m::MIME"text/plain", t::D3Tree)
    # TODO: handle tree expand depth here
    show(io, m, D3TreeView(D3TreeNode(t, 1), get(t.options, :init_expanded, false) ? typemax(Int) : 3))
end
Base.show(io::IO, m::MIME"text/plain", v::D3TreeView) = shownode(io, v.root, v.depth, "", "")

# Support for Visual Studio Code plot pane:
Base.showable(::MIME"juliavscode/html", ::D3Tree) = true
function Base.show(@nospecialize(io::IO), ::MIME"juliavscode/html", @nospecialize(t::D3Tree))
    show(io, MIME("text/html"), t)
end
