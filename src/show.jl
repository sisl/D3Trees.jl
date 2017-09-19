function Base.show(f::IO, m::MIME"text/html", t::D3Tree)
    tree_json = json(t)
    root_id = 1
    css = readstring(joinpath(dirname(@__FILE__()), "..", "css", "tree_vis.css"))
    js = readstring(joinpath(dirname(@__FILE__()), "..", "js", "tree_vis.js"))
    div = "treevis$(randstring())"

    html_string = """
        <html>
        <head>
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
