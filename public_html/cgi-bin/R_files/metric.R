#
#
# kjolley
# Sun Apr 28 03:40:23 PDT 2013
#
#
metric <- function(g_local, mfile) {
  if (interactive()) cat("R: metric.R: Calculating metrics. This can take a while on large networks...\n")

  cat(paste("Edges", length(E(g_local)$weight), "\n", sep=":"), file=mfile, append=FALSE)
  cat(paste("Vertices", length(V(g_local)), "\n", sep=":"), file=mfile, append=TRUE)

  if (interactive())   cat("R: metric.R: calculating local transitivity...\n")
  V(g_local)$lcc <- transitivity(g_local, type="local")
  if (interactive())   cat("R: metric.R: calculating global transitivity...\n")
  global_lcc     <- transitivity(g_local, type="global")
  cat(paste("Mean Local Clustering Coefficient", global_lcc, "\n", sep=":"), file=mfile, append=TRUE)

  if (interactive())   cat("R: metric.R: calculating vertex betweenness...\n")
  V(g_local)$betweenness_vertex <- betweenness(g_local)
  if (interactive())   cat("R: metric.R: calculating edge betweenness...\n")
  E(g_local)$betweenness_edge   <- edge.betweenness(g_local)

  if (interactive())   cat("R: metric.R: calculating vertex degree...\n")
  V(g_local)$degree <- degree(g_local)

  if (interactive())   cat("R: metric.R: calculating degree probability density...\n")
  V(g_local)$dpd <- V(g_local)$degree/sum(V(g_local)$degree)

  if (interactive())   cat("R: metric.R: calculating vertex closeness centrality (in) ...\n")
  V(g_local)$closeness_in  <- closeness(g_local, mode="in")
  if (interactive())   cat("R: metric.R: calculating vertex closeness centrality (out) ...\n")
  V(g_local)$closeness_out <- closeness(g_local, mode="out")

  if (!exists("damping")) damping=0.85
  if (interactive())   cat("R: metric.R: calculating page.rank...\n")
  V(g_local)$pr     <- page.rank(g, damping=damping)$vector

  if (interactive())   cat("R: metric.R: calculating eigenvector centrality...\n")
  V(g_local)$evcent <- evcent(g_local)$vector

  if (interactive())   cat("R: metric.R: calculating network diameter (longest shortest path!)...\n")
  diameter_local <- diameter(g_local)
  cat(paste("Diameter", diameter_local, "\n", sep=":"), file=mfile, append=TRUE)

  if (interactive())   cat("R: metric.R: average shortest path... )\n")
  average_shortest_path_local <- average.path.length(g_local)
  cat(paste("Average Shortest Path", average_shortest_path_local, "\n", sep=":"), file=mfile, append=TRUE)

  if (interactive())   cat("R: metric.R: calculating graph strength (in) ...)\n")
  V(g_local)$graph_strength_in  <- graph.strength(g_local, mode="in")
  if (interactive())   cat("R: metric.R: calculating graph strength (out) ...)\n")
  V(g_local)$graph_strength_out <- graph.strength(g_local, mode="out")
  if (interactive())   cat("R: metric.R: calculating graph strength (total) ...)\n")
  V(g_local)$graph_strength_tot <- V(g_local)$graph_strength_out + V(g_local)$graph_strength_in

#  if (interactive())   cat("R: metric.R: calculating edge connectivity...)\n")
# E(g_local)$connectivity_edge   <- edge.connectivity(g_local)
#  if (interactive())   cat("R: metric.R: calculating vertex connectivity...)\n")
# V(g_local)$connectivity_vertex <- vertex.connectivity(g_local)

  if (interactive())   cat("R: metric.R: finding number of communities...)\n")
  numcomm <- length(unique(V(g_local)$community))
  cat(paste("Number of Communities", numcomm, "\n", sep=":"), file=mfile, append=TRUE)

  if (interactive())   cat("R: metric.R: calculating graph density...)\n")
  density_local <- graph.density(g_local, loops=FALSE)
  cat(paste("Density", density_local, "\n", sep=":"), file=mfile, append=TRUE)

  return(g_local)
}
