function Base.show(f::IO, m::MIME"text/html", t::D3Tree)
    tree_json = json(t)
    root_id = 1
    css = readstring(joinpath(dirname(@__FILE__()), "..", "css", "tree_vis.css"))
    js = readstring(joinpath(dirname(@__FILE__()), "..", "js", "tree_vis.js"))
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
            $js
            })();
        </script>
        </div>
        </body>
        </html>
    """

    println(f,html_string)
end

# fallback when only the repl is available
Base.show(io::IO, m::MIME"text/plain", t::D3Tree) = show(io, m, D3TreeView(D3TreeNode(t, 1), 3))
Base.show(io::IO, m::MIME"text/plain", v::D3TreeView) = shownode(io, v.root, v.depth, "", "")
