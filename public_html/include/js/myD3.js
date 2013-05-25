  <script type="text/javascript">
    function myradius() {
      var myradios = document.getElementsByName('whichradius');
      var theradius;
      for (var i = 0, length = myradios.length; i < length; i++) {
        if (myradios[i].checked) { theradius = myradios[i].value; }
      };
      return (theradius.match('pr'));
    };

    var radtype = myradius();
    var width   = 900,  // i think these are moon units
        height  = 900;
    var color   = d3.scale.category20();
    var force   = d3.layout.force()
          .gravity(0.1)
          .charge(      function(d) { return (d.charge);       })
          .linkDistance(function(d) { return (d.linkDistance); })
          .linkStrength(function(d) { return (d.linkStrength); })
          .size([width, height]);
    var svg = d3.select("body").append("svg")
          .attr("width",  width)
          .attr("height", height);
    var div = d3.select("body").append("div")
          .attr("class", "tooltip")
          .style("opacity", 0);
    
    d3.json("__JSON_FILE__", function(error, graph) {
        force
          .nodes(graph.nodes)
          .links(graph.links)
          .start();
      var link = svg.selectAll(".link")
          .data(graph.links)
          .enter().append("line")
          .attr("class", "link")
          .style("stroke", "grey") 
          .style("stroke-width",   function(d) { return (d.width); })
          .style("stroke-opacity", function(d) { return (d.linkStrength/2); });
      var node = svg.selectAll(".node")
          .data(graph.nodes)
          .enter().append("circle")
          .attr( "class", "node")
          .attr( "r",      function(d) { return radtype ? d.pr_rad : d.evc_rad; })
          .style("fill",   function(d) { return color(d.community)})
          .style("stroke", function(d) { return ((d.isperson==1) ? "white" : "grey")}) 
          .style("stroke-width", function(d) { return Math.max(d.radius/10,1)}) 
          .attr( "mytext", function(d) { return (
                     d.name + "<br/>" +
                     "   community: " + d.community + "<br/>" +
                     "   page.rank: " + d.pr        + "<br/>" +
                     " eigenvector: " + d.evcent);
           })
          .call(force.drag)
          .on("mouseover", function(d) {
              div.transition()
                 .duration(200);
              div.html(function(d) { return (node.mytext) })
                 .style("opacity", 0.9)
                 .style("left", (d3.event.pageX - 0)  + "px")
                 .style("top",  (d3,event.pageY - 28) + "px");
          })
          .on("mouseout", function(d) {
              div.transition()
                 .duration(500)
                 .style("opacity", 0);
          });
//           node.append("title")
//             .text(function(d) { return (
//              d.name + "\n" +
//              "   community: " + d.community + "\n" +
//              "   page.rank: " + d.pr        + "\n" +
//              " eigenvector: " + d.evcent);
//          });
      force.on("tick", function () {
        var q = d3.geom.quadtree(graph.nodes);
        var i = 0;
        var n = graph.nodes.length;
        while (++i < n) {
          q.visit(collide(graph.nodes[i]));
        }
        link
          .attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });
        node
          .attr("cx", function(d) { return d.x;})
          .attr("cy", function(d) { return d.y;});
      });
    });

    // https://github.com/mbostock/d3/blob/gh-pages/talk/20111018/collision.html#L76-101
    // i really dislike this code. i hope nobody ever looks here. 
    function collide(node) {
      var r1  = 2 + (radtype ? node.pr_rad : node.evc_rad);
      var nx1 = node.x - r1;
      var nx2 = node.x + r1;
      var ny1 = node.y - r1;
      var ny2 = node.y + r1;
      return function(quad, x1, y1, x2, y2) {
        if (quad.point && (quad.point !== node)) {
          var x = node.x - quad.point.x;
          var y = node.y - quad.point.y;
          var l = Math.sqrt(x * x + y * y);
          var r = radtype ? (node.pr_rad + quad.point.pr_rad) : (node.evc_rad + quad.point.evc_rad);
          if (l < r) {
            l = (l - r) / l * .5;
            node.x -= x *= l;
            node.y -= y *= l;
            quad.point.x += x;
            quad.point.y += y;
          }
        }
        return x1 > nx2
            || x2 < nx1
            || y1 > ny2
            || y2 < ny1;
      };
    }

    // resize the nodes, not the screen
    function resize() {
      radtype = myradius();
      d3.selectAll(".node").transition()
        .duration(750)
        .attr( "r", function(d) { return (radtype ? d.pr_rad : d.evc_rad)})
        .attr("cx", function(d) { return d.x+0.1;})
    ;}

  </script>
