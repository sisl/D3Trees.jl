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


function prepareSubtreeRequest(dataID){
    let request = new Object();
    request.tree_div_id = div;
    request.subtree_root_id = dataID+1; // shift to 1-based indexing in Julia
    return JSON.stringify(request);
}

// ======== Websocket code
var socket = new WebSocket(ws_url);

// Connect
socket.addEventListener('open', function (event) {
    console.log(`[ws-open] connection established at ${url}`)
    // socket.send('READY');
    // setDisplay("Open");
});

// Handle server messages
socket.addEventListener('message', function (event) {
    console.log(`[ws-message] received ${event.data}`)
    // alert(['Message from server ', event.data]);
    // i++;
    // setDisplay(['Message from server: ',i, ' - ',  event.data]);
});

// Handle server close
socket.addEventListener('close', function (event) {
    // alert(['Message from server ', event.data]);
    // setDisplay(['Connection to server CLOSED: ',i, ' - ',  event.data]);
    if (event.wasClean) {
        console.log(`[ws-close] connection closed cleanly, code=${event.code} reason=${event.reason}`);
      } else {
        // e.g. server process killed or network down
        // event.code is usually 1006 in this case
        console.log('[ws-close] connection died');
      }
});

// Handle server error
socket.addEventListener('error', function (event) {
    // alert(['Message from server ', event.data]);
    // setDisplay(['Connection to server ERRORED: ',i, ' - ',  event.data]);
    alert(`[ws-error] ${error.message}`);
});


// ======== Fetching subtree data
function mockFetchChildren(dataID){
    // Call websocket with current node id
    // Receive data regarding children

    request_json = prepareSubtreeRequest(dataID);

    console.log(request_json);

    mock_ws_responses = {
        2: "{\"children\":[[8,9],[],[],[11,12],[],[]],\"tooltip\":[\"8 (d=3) -> [16, 17]\",\"16 (d=4) -> [32, 33]\",\"17 (d=4) -> [34, 35]\",\"9 (d=3) -> [18, 19]\",\"18 (d=4) -> [36, 37]\",\"19 (d=4) -> [38, 39]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[12,9,8,11],\"text\":[\"8 (d=3) -> [16, 17]\",\"16 (d=4) -> [32, 33]\",\"17 (d=4) -> [34, 35]\",\"9 (d=3) -> [18, 19]\",\"18 (d=4) -> [36, 37]\",\"19 (d=4) -> [38, 39]\"],\"options\":{},\"root_children\":[7,10],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
        3: "{\"children\":[[14,15],[],[],[17,18],[],[]],\"tooltip\":[\"10 (d=3) -> [20, 21]\",\"20 (d=4) -> [40, 41]\",\"21 (d=4) -> [42, 43]\",\"11 (d=3) -> [22, 23]\",\"22 (d=4) -> [44, 45]\",\"23 (d=4) -> [46, 47]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[15,14,17,18],\"text\":[\"10 (d=3) -> [20, 21]\",\"20 (d=4) -> [40, 41]\",\"21 (d=4) -> [42, 43]\",\"11 (d=3) -> [22, 23]\",\"22 (d=4) -> [44, 45]\",\"23 (d=4) -> [46, 47]\"],\"options\":{},\"root_children\":[13,16],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
        5: "{\"children\":[[20,21],[],[],[23,24],[],[]],\"tooltip\":[\"12 (d=3) -> [24, 25]\",\"24 (d=4) -> [48, 49]\",\"25 (d=4) -> [50, 51]\",\"13 (d=3) -> [26, 27]\",\"26 (d=4) -> [52, 53]\",\"27 (d=4) -> [54, 55]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[21,20,24,23],\"text\":[\"12 (d=3) -> [24, 25]\",\"24 (d=4) -> [48, 49]\",\"25 (d=4) -> [50, 51]\",\"13 (d=3) -> [26, 27]\",\"26 (d=4) -> [52, 53]\",\"27 (d=4) -> [54, 55]\"],\"options\":{},\"root_children\":[19,22],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
        6: "{\"children\":[[26,27],[],[],[29,30],[],[]],\"tooltip\":[\"14 (d=3) -> [28, 29]\",\"28 (d=4) -> [56, 57]\",\"29 (d=4) -> [58, 59]\",\"15 (d=3) -> [30, 31]\",\"30 (d=4) -> [60, 61]\",\"31 (d=4) -> [62, 63]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[26,30,29,27],\"text\":[\"14 (d=3) -> [28, 29]\",\"28 (d=4) -> [56, 57]\",\"29 (d=4) -> [58, 59]\",\"15 (d=3) -> [30, 31]\",\"30 (d=4) -> [60, 61]\",\"31 (d=4) -> [62, 63]\"],\"options\":{},\"root_children\":[25,28],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
    };

    console.log(["Fetched mocked subtree, jid:", dataID]);

    return  JSON.parse(mock_ws_responses[dataID]);
}

function fetchChildren(dataID){
    // Call websocket with current node id
    // Receive data regarding children

    request_json = prepareSubtreeRequest(dataID);

    console.log(request_json);

    mock_ws_responses = {
        2: "{\"children\":[[8,9],[],[],[11,12],[],[]],\"tooltip\":[\"8 (d=3) -> [16, 17]\",\"16 (d=4) -> [32, 33]\",\"17 (d=4) -> [34, 35]\",\"9 (d=3) -> [18, 19]\",\"18 (d=4) -> [36, 37]\",\"19 (d=4) -> [38, 39]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[12,9,8,11],\"text\":[\"8 (d=3) -> [16, 17]\",\"16 (d=4) -> [32, 33]\",\"17 (d=4) -> [34, 35]\",\"9 (d=3) -> [18, 19]\",\"18 (d=4) -> [36, 37]\",\"19 (d=4) -> [38, 39]\"],\"options\":{},\"root_children\":[7,10],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
        3: "{\"children\":[[14,15],[],[],[17,18],[],[]],\"tooltip\":[\"10 (d=3) -> [20, 21]\",\"20 (d=4) -> [40, 41]\",\"21 (d=4) -> [42, 43]\",\"11 (d=3) -> [22, 23]\",\"22 (d=4) -> [44, 45]\",\"23 (d=4) -> [46, 47]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[15,14,17,18],\"text\":[\"10 (d=3) -> [20, 21]\",\"20 (d=4) -> [40, 41]\",\"21 (d=4) -> [42, 43]\",\"11 (d=3) -> [22, 23]\",\"22 (d=4) -> [44, 45]\",\"23 (d=4) -> [46, 47]\"],\"options\":{},\"root_children\":[13,16],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
        5: "{\"children\":[[20,21],[],[],[23,24],[],[]],\"tooltip\":[\"12 (d=3) -> [24, 25]\",\"24 (d=4) -> [48, 49]\",\"25 (d=4) -> [50, 51]\",\"13 (d=3) -> [26, 27]\",\"26 (d=4) -> [52, 53]\",\"27 (d=4) -> [54, 55]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[21,20,24,23],\"text\":[\"12 (d=3) -> [24, 25]\",\"24 (d=4) -> [48, 49]\",\"25 (d=4) -> [50, 51]\",\"13 (d=3) -> [26, 27]\",\"26 (d=4) -> [52, 53]\",\"27 (d=4) -> [54, 55]\"],\"options\":{},\"root_children\":[19,22],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
        6: "{\"children\":[[26,27],[],[],[29,30],[],[]],\"tooltip\":[\"14 (d=3) -> [28, 29]\",\"28 (d=4) -> [56, 57]\",\"29 (d=4) -> [58, 59]\",\"15 (d=3) -> [30, 31]\",\"30 (d=4) -> [60, 61]\",\"31 (d=4) -> [62, 63]\"],\"link_style\":[\"\",\"\",\"\",\"\",\"\",\"\"],\"title\":\"Julia D3Tree\",\"unexpanded_children\":[26,30,29,27],\"text\":[\"14 (d=3) -> [28, 29]\",\"28 (d=4) -> [56, 57]\",\"29 (d=4) -> [58, 59]\",\"15 (d=3) -> [30, 31]\",\"30 (d=4) -> [60, 61]\",\"31 (d=4) -> [62, 63]\"],\"options\":{},\"root_children\":[25,28],\"style\":[\"\",\"\",\"\",\"\",\"\",\"\"]}",
    };

    console.log(["Fetched mocked subtree, jid:", dataID]);

    return  JSON.parse(mock_ws_responses[dataID]);
}

function addTreeData(dataID){
    st = fetchChildren(dataID);

    console.log(["Fetched mocked subtree", st]);
    treeData.unexpanded_children.delete(dataID);

    treeData.children[dataID]=st.root_children;
    treeData.children.push(...(st.children));
    treeData.unexpanded_children = new Set([...treeData.unexpanded_children, st.unexpanded_children]);
    treeData.text.push(...st.text);
    treeData.tooltip.push(...st.tooltip);
    treeData.style.push(...st.style);
    treeData.link_style.push(...st.link_style);
}

// ==== Showing trees ====

function showTree() {
    treeData.unexpanded_children = new Set(treeData.unexpanded_children);
        
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

    function treeDataNotDownloaded(dataID){
        return treeData.unexpanded_children.has(dataID);
    }

    function initializeChildren(d, expandLevel) {
        // fetch missing children
        if (treeDataNotDownloaded(d.dataID)) {
            console.log(["Adding nodes!", d.dataID]);
            addTreeData(d.dataID);
        }
      
      // create children
      var children = treeData.children[d.dataID];
      d.children = [];
      if (children) {
        for (var i = 0; i < children.length; i++) {
          var cid = children[i];
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
          //=== Debug helper
          text = '=' + d.dataID + '= ' + text;
          //===
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
