if (typeof $ === 'undefined') {
    loadScript("https://code.jquery.com/jquery-3.1.1.min.js", run);
} else {
    run();
}

function run() {
    if (typeof d3 === 'undefined') {
        loadScript("https://d3js.org/d3.v3.js", showTree);
    } else {
        showTree();
    }
}

function loadScript(url, callback)
{
    console.log("starting script load...")
    // Adding the script tag to the head as suggested before
    var head = document.getElementsByTagName('head')[0];
    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = url;

    // Then bind the event to the callback function.
    // There are several events for cross browser compatibility.
    script.onreadystatechange = callback;
    script.onload = callback;

    // Fire the loading
    head.appendChild(script);
}

function showTree() {
        
    // var margin = {top: 20, right: 120, bottom: 20, left: 120},
    var margin = {top: 20, right: 120, bottom: 80, left: 120},
        width = $("#"+div).width() - margin.right - margin.left,
        height = svgHeight - margin.top - margin.bottom;
        // TODO make height a parameter of TreeVisualizer

    var i = 0,
        root;

    var tree = d3.layout.tree()
        .size([width, height]);

    var diagonal = d3.svg.diagonal();
        //.projection(function(d) { return [d.y, d.x]; });
        // uncomment above to make the tree go horizontally

    // see http://stackoverflow.com/questions/16265123/resize-svg-when-window-is-resized-in-d3-js
    if (d3.select("#"+div+"_svg").empty()) {
        $(".d3twarn").remove();
        d3.select("#"+div).append("svg")
            .attr("id", div+"_svg")
            .attr("width", width + margin.right + margin.left)
            .attr("height", height + margin.top + margin.bottom);
    }

    d3.select("#"+div+"_svg").selectAll("*").remove();

    var svg = d3.select("#"+div+"_svg")
        .append("g")
            .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

    // console.log("tree data:");
    // console.log(treeData[rootID]);
    root = createDisplayNode(rootID, initExpand);
    root.x0 = width / 2;
    root.y0 = 0;

    update(root, initDuration);
    console.log("tree should appear");

    function createDisplayNode(id, expandLevel) {
      var dnode = {"dataID":id,
                   "children": null,
                   "_children":null};
      if (expandLevel > 0) {
        initializeChildren(dnode, expandLevel);
      }
      return dnode;
    }

    function initializeChildren(d, expandLevel) {
      // create children
      var children = treeData.children[d.dataID];
      d.children = [];
      if (children) {
        for (var i = 0; i < children.length; i++) {
          var cid = children[i]-1;
          d.children.push(createDisplayNode(cid, expandLevel-1));
        }
      }
    }

    /**
     * Recursively called to update each node in the tree.
     * 
     * source is a d3 node that has position, etc.
    */
    function update(source, duration) {

      width = $("#"+div).width() - margin.right - margin.left,
      height = $("#"+div).height() - margin.top - margin.bottom;

      tree.size([width,height]);
      d3.select("#"+div).attr("width", width + margin.right + margin.left)
            .attr("height", height + margin.top + margin.bottom);
      d3.select("#"+div+"_svg").attr("width", width + margin.right + margin.left)
             .attr("height", height + margin.top + margin.bottom);


      // Compute the new tree layout.
      var nodes = tree.nodes(root).reverse(),
          links = tree.links(nodes);


      // Update the nodes…
      var node = svg.selectAll("g.node")
          .data(nodes, function(d) { return d.id || (d.id = ++i); });

      // Enter any new nodes at the parent's previous position.
      var nodeEnter = node.enter().append("g")
          .attr("class", "node")
          .attr("transform", function(d) { return "translate(" + source.x0 + "," + source.y0 + ")"; })
          .on("click", click)

      nodeEnter.append("circle")
          .attr("r", "10px")
          .attr("style", function(d) { return treeData.style[d.dataID]; } )

      var tbox = nodeEnter.append("text")
          .attr("y", 25)
          .attr("text-anchor", "middle")
          //.text( function(d) { return treeData.text[d.dataID]; } )
          .style("fill-opacity", 1e-6);

      tbox.each( function(d) {
          var el = d3.select(this)
          var text = treeData.text[d.dataID];
          var lines = text.split('\n');
          for (var i = 0; i < lines.length; i++) {
              var tspan = el.append("tspan").text(lines[i]);
              if (i > 0) {
                  tspan.attr("x", 0).attr("dy", "1.2em");
              }
          }
      });

      //tooltip
      nodeEnter.append("title").text( function(d) { return treeData.tooltip[d.dataID];} );

      // Transition nodes to their new position.
      var nodeUpdate = node.transition()
          .duration(duration)
          .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

      nodeUpdate.select("text")
          .style("fill-opacity", 1);

      // Transition exiting nodes to the parent's new position.
      var nodeExit = node.exit().transition()
          .duration(duration)
          .attr("transform", function(d) { return "translate(" + source.x + "," + source.y + ")"; })
          .remove();

      nodeExit.select("text")
          .style("fill-opacity", 1e-6);

      // Update the links…
      var link = svg.selectAll("path.link")
          .data(links, function(d) { return d.target.id; });

      // Enter any new links at the parent's previous position.
      // XXX link width should be based on transition data, not node data
      link.enter().insert("path", "g")
          .attr("class", "link")
          .attr("style", function(d) {
              var ls = treeData.link_style[d.target.dataID];
              return ls;
          } )
          .attr("d", function(d) {
            var o = {x: source.x0, y: source.y0};
            return diagonal({source: o, target: o});
          });

      // Transition links to their new position.
      link.transition()
          .duration(duration)
          .attr("d", diagonal);

      // Transition exiting nodes to the parent's new position.
      link.exit().transition()
          .duration(duration)
          .attr("d", function(d) {
            var o = {x: source.x, y: source.y};
            return diagonal({source: o, target: o});
          })
          .remove();

      // Stash the old positions for transition.
      nodes.forEach(function(d) {
        d.x0 = d.x;
        d.y0 = d.y;
      });
    }

    // Toggle children on click.
    function click(d) {
      if (d.children) {
        d._children = d.children;
        d.children = null;
      } else if (d._children) {
        d.children = d._children;
        d._children = null;
      } else {
        initializeChildren(d, 1);
      }
      update(d, 750);
    }

}
