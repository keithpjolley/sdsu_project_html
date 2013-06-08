  <script type="text/javascript">

    // https://github.com/mbostock/d3/blob/gh-pages/talk/20111018/collision.html#L76-101
    // i really dislike this code. i hope nobody ever looks here. but it works. and that's hard to argue with.
    function collide(node) {
//    var r1  = 2 + (radtype ? node.pr_rad : node.evc_rad);
      var r1  = 1 + node.radius
      var nx1 = node.x - r1;
      var nx2 = node.x + r1;
      var ny1 = node.y - r1;
      var ny2 = node.y + r1;
      return function(quad, x1, y1, x2, y2) {
        if (quad.point && (quad.point !== node)) {
          var x = node.x - quad.point.x;
          var y = node.y - quad.point.y;
          var l = Math.sqrt(x * x + y * y);
//        var r = radtype ? (node.pr_rad + quad.point.pr_rad) : (node.evc_rad + quad.point.evc_rad);
          var r = node.radius + quad.point.radius;
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
      }
    ;}

    // resize the nodes, not the screen
//    function resize() {
//      radtype = myradius();
//      d3.selectAll(".node").transition()
//        .duration(750)
//        .attr( "r", function(d) { return (radtype ? d.pr_rad : d.evc_rad)});
//    }

    function mymin(dec) {  // i do realize this would be the time to demonstrate my knowledge of recursion and unreadable code.
      if (dec < 1) { return 0; }
      var ret = 1/2;
      while (dec>0) {
        ret /= 10;
        dec--;
      }
      return ret;
    }

    // http://java-scripts.net/javascripts/Format-Number.phtml
    function fmt(pnumber, decimals){
      if (isNaN(parseFloat(pnumber)))  { return ''};
      if (pnumber==0)                  { return 0};
      if (pnumber=='')                 { return ''};
      if (!isFinite(pnumber))          { return ''};
      
      if (pnumber < mymin(decimals)/2) { return '0.0'};

      var snum = new String(pnumber);
      var sec = snum.split('.');
      var whole = parseFloat(sec[0]);
      var result = '';
      if (sec.length > 1) {
        var dec = new String(sec[1]);
        dec = String(parseFloat(sec[1])/Math.pow(10,(dec.length - decimals)));
        dec = String(whole + Math.round(parseFloat(dec))/Math.pow(10,decimals));
        var dot = dec.indexOf('.');
        if(dot == -1){
          dec += '.';
          dot = dec.indexOf('.');
        }
        while (dec.length <= dot + decimals) { dec += '0'; }
        result = dec;
      } else {
        var dot;
        var dec = new String(whole);
        dec += '.';
        dot = dec.indexOf('.');
        while (dec.length <= dot + decimals) { dec += '0'; }
        result = dec;
      }
      return result;
    }

//    function myradius() {
//      var myradios = document.getElementsByName('whichradius');
//      var theradius;
//      for (var i = 0, length = myradios.length; i < length; i++) {
//        if (myradios[i].checked) { theradius = myradios[i].value; }
//      };
//      return (theradius.match('pr'));
//    };

//    var radtype = myradius();
    var width   = 900,  // i think these are moon units
        height  = 900;
    var color   = d3.scale.category20();
    var force   = d3.layout.force()
          .gravity(0.1)
          .charge(      function(d) { return (d.charge)         })
          .linkDistance(function(d) { return ((d.source.radius + d.target.radius)*5) })
          .linkStrength(function(d) { return (d.linkStrength/4) })
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
          .style("stroke",         function(d) { return (color(d.source.community)) })
          .style("stroke-width",   function(d) { return (d.width); })
          .style("stroke-opacity", function(d) { return (d.linkStrength/2) });
      var node = svg.selectAll(".node")
          .data(graph.nodes)
          .enter().append("circle")
          .attr( "class", "node")
//        .attr( "r",      function(d) { return radtype ? d.pr_rad : d.evc_rad; })
          .attr( "r",      function(d) { return d.radius; })
          .style("fill",   function(d) { return color(d.community)})
          .style("stroke", function(d) { return ((d.isperson==1) ? "white" : "grey")})
//        .style("stroke-width", function(d) { return Math.max(d.radius/10,1)})
          .style("stroke-width", function(d) { return Math.max(d.radius/10,1)})
          .call(force.drag)
          .on("mouseover", function(d) {
               //Get this bar's x/y values, then augment for the tooltip
               var xPosition = parseFloat(d3.select(this).attr("cx")) + 30;
               var yPosition = parseFloat(d3.select(this).attr("cy")) - 70;
               //Update the tooltip position and value
               d3.select("#tooltip")
                 .style("background-color", tinycolor.lighten(color(d.community), 10))
                 .style("left", xPosition + "px")
                 .style("top",  yPosition + "px")
                 // fmt numbers that 'may' be floats. let ints go through as is
                 .select("#tip")
                 .html('<pre><strong>'  +
                    '                  Name: ' + d.name               + '</strong><br />' +
                    '              PageRank: ' + fmt(d.pr, 4)         + '<br />'          +
                    'Eigenvector Centrality: ' + fmt(d.evcent, 4)     + '<br />'          +
                    'Clustering Coefficient: ' + fmt(d.lcc, 4)        + '<br />'          +
                    '                Degree: ' + d.degree             + '<br />'          +
                    '    Degree Probability: ' + fmt(d.dpd, 4)        + '<br />'          +
//                  '             Community: ' + d.community          + '<br />'          +
                    '           Strength In: ' + d.graph_strength_in  + ' <img alt="" src="../include/images/incoming_edge.png" /><br />' +
                    '          Strength Out: ' + d.graph_strength_out + ' <img alt="" src="../include/images/outgoing_edge.png" /><br />' +
                    '        Strength Total: ' + d.graph_strength_tot + '<br />'          +
                    '</pre>'
                 );
               //Show the tooltip
               d3.select("#tooltip").classed("hidden", false);
            })
          .on("mouseout", function() {
              //Hide the tooltip
              d3.select("#tooltip").classed("hidden", true);
            });

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

  </script>
