##
#
# kjolley
# Sun Apr 21 18:56:52 PDT 2013
#
##

# create JSON output. you wouldn't know there's R JSON libraries. :/
# brilliant solution from Wei Luo
# https://theweiluo.wordpress.com/2011/09/30/r-to-json-for-d3-js-and-protovis/
dfToJSONarray <- function(name, dtf){
  clnms <- colnames(dtf)
  name.value <- function(i){
    quote <- '';
    if((class(dtf[, i])!='numeric')&&(class(dtf[,i])!='integer')){
      quote <- '"';
    } 
    paste('"', i, '":', quote, dtf[,i], quote, sep='')
  } 
  objs <- apply(sapply(clnms, name.value), 1, function(x){paste(x, collapse=',',sep='')})
  objs <- paste('    {', objs, '}', sep='')
  objs <- paste('[\n ', paste(objs, collapse=',\n '), '\n]', sep='')
  objs  <- paste(' "', name, '":', objs, sep='')
  return(objs)
}   

graphToJSON <- function(g_local) {
  g_local <- mysimplify(g_local)
  vertices_local <- get.data.frame(g_local, what="vertices")
  edges_local <- get.data.frame(g_local, what="edges")
  rm(g_local)
  mypalette <- brewer.pal(12, "Paired")

  # get just the columns needed and name to what D3 is wanting
  # // that was nice during testing, but now i know it works, let's junk it up!
  #  vertices_local <- subset(vertices_local, select=c("name", "community"))

  # this guarantees that the vertices are unique and in order
  # i think simplify(g) already assured that but better safe than hosed
  vertices_local <- vertices_local[match(sort(unique(vertices_local$name)),vertices_local$name),]

  # index makes sure that the edges point to the correct names
  vertices_local$index <- 0:(nrow(vertices_local)-1)

  edges_local <- merge(edges_local, vertices_local, by.x="from", by.y="name")
  setnames(edges_local, c("index"), c("source"))

  edges_local <- merge(edges_local, vertices_local, by.x="to", by.y="name")
  setnames(edges_local, c("index"), c("target"))

  # change out all NaN numbers to NULL for json. 
  # see http://www.json.org/json.ppt, slide 16.  alright. so i give up.
  # change all Inf/-Inf/NaN to NaN and clean up in post process. :(
  vertices_local[vertices_local==1/0]  <- 0/0  # assigning <- NULL comes up as an error.
  vertices_local[vertices_local==-1/0] <- 0/0  # assigning <- NULL comes up as an error.

# create some parameters for plotting
  vertices_local$evc_rad   <-  map(vertices_local$evcent, 5, 30) # radius of vertices in pixels
  vertices_local$pr_rad    <-  map(vertices_local$pr,     5, 30) # radius of vertices in pixels
  vertices_local$radius    <-  (vertices_local$evc_rad + vertices_local$pr_rad)/2.0
# gravity                  <-  exp(-50/nrow(vertices_local))/2 + 0.25  # this is a scalar.
  vertices_local$gravity   <-  0.15 # overload the dataframe out of convenience
  vertices_local$color     <-  mypalette[(vertices_local$community-1)%%12+1]  # use colorbrewer instead of D3 colors
# vertices_local$charge    <- -map(vertices_local$betweenness_vertex, 20, 50) # strength of edge

  edges_local              <-  subset(edges_local, select=c(source, target, weight))
  edges_local$width        <-  map(edges_local$weight,    1,     5) # how many pixels wide to draw the edges
# this is calculated in myD3.js now.
# edges_local$linkStrength <-  map(edges_local$weight, 0.25,  0.95) # rigidity
# edges_local$linkDistance <-  map(edges_local$weight,  100,    50) # note the decreasing map

# remove anything we don't want passed to the output file
# vertices_local           <-  subset(vertices_local, select=-c(index, pr))

  json <- paste(
     "{\n", dfToJSONarray("nodes", vertices_local), ",\n", dfToJSONarray("links", edges_local), "\n}\n"
  )
  return(json)
}
