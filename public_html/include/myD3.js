    <script type="text/javascript">
    var width  = 900,  // i think these are moon units
        height = 900;
    var color = d3.scale.category20();
    var force = d3.layout.force()
          .charge( function(d) {      return (d.charge);       })
          .gravity(0.1)
//        .gravity(function(d) {      return (d.gravity);      })
          .linkDistance(function(d) { return (d.linkDistance); })
          .linkStrength(function(d) { return (d.linkStrength); })
          .size([width, height]);
    var svg = d3.select("body").append("svg")
          .attr("width",  width)
          .attr("height", height);
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
          .attr( "r",      function(d) { return d.radius;})
          .style("fill",   function(d) { return color(d.community);})
          .style("stroke", function(d) { if (d.isperson==1) { return "grey"; } else { return "white"; }; }) 
          .style("stroke-width", function(d) { return Math.max(d.radius/10,1); }) 
          .call(force.drag);
      node.append("title")
          .text(function(d) { return d.name; });
      force.on("tick", function() {
        link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });
        node.attr("cx", function(d) {return d.x;})
          .attr("cy", function(d) {return d.y;});
      });
    });
  </script>
