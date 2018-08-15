function Base.show(f::IO, m::MIME"text/html", t::D3Tree)
    tree_json = json(t)
    root_id = 1
    css = read(joinpath(dirname(@__FILE__()), "..", "css", "tree_vis.css"), String)
    js = read(joinpath(dirname(@__FILE__()), "..", "js", "tree_vis.js"), String)
    div = "treevis$(randstring())"

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
            var initExpand = $(get(t.options, :init_expand, 0))
            var initDuration = $(get(t.options, :init_duration, 750))
            var svgHeight = $(get(t.options, :svg_height, 600))
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
end

# fallback when only the repl is available
function Base.show(io::IO, m::MIME"text/plain", t::D3Tree)
    show(io, m, D3TreeView(D3TreeNode(t, 1), get(t.options, :init_expanded, false) ? typemax(Int) : 3))
end
Base.show(io::IO, m::MIME"text/plain", v::D3TreeView) = shownode(io, v.root, v.depth, "", "")
