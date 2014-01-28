##
# contains odds and ends functions
# kjolley
# Sun Apr 21 18:22:53 PDT 2013
#
##

# remaps a number (vector) from one range to another.
# modeled from map in processing except start1 and stop1 are embedded into "value"
# http://processing.org/reference/map_.html
map <- function(value, start2, stop2) {
  epsilon <- 1e-7 # protect against /0
  mx <- max(value)
  mn <- min(value)
  if ((mx-mn)<epsilon) {
    rep((start2+stop2)/2,length(value))
  } else {
    (stop2-start2)*(value-mn)/(mx-mn)+start2
  }
}

# given an input file of lines and lines of raw edges, return a graph
# see "setnames" below for expected columns
getgraph <- function(raw) {
  # read in our table of unique edges - insert a weight of 1 to each row - one message per row
  d <- data.table(read.delim(raw, header=FALSE))
  if (ncol(d)==3) {
    setnames(d, c("source", "target", "weight"))
  } else {
    setnames(d, c("index", "source", "target", "list", "subject", "datesent"))
    if (interactive()) cat("R: Removing unused columns: /tmp/raw\n")
    d <- subset(d, select=c("source", "target"))
    d$weight <- 1
  }
  if (interactive()) cat(paste("R: Collected", nrow(d), "unique edges.\n"))
  if (interactive()) cat("R: Creating graph from edges.\n")
  g <- graph.data.frame(d, directed=TRUE)
  rm(d) # housekeeping - free up some memory

  # this unassuming function collapses all our edges of weight 1 into single edges of weight (sum to/from combos)
  g <- simplify(g, edge.attr.comb="sum")
  g <- mysimplify(g) # remove any vertices without edges

  # add an "is this vertex a person?" attribute
  V(g)$isperson <- isperson(V(g)$name, maillistdir)
  return(g)
}

# remove all edges below a certain threshold. remove any orphaned nodes.
edgecutter <- function(g_local, cutline) {
  g_local  <- delete.edges(g_local, E(g_local)[weight<=cutline])
  g_local  <- mysimplify(g_local) # remove any vertices without edges
  return(g_local)
}

# given a graph and a percentage, return only the top N% of the graph, based on $key metric
mibnodes <- function(g_local, N) {
  g_local <- delete.vertices(g_local, V(g_local)$key < quantile(V(g_local)$key, prob=N/100))
  g_local <- mysimplify(g_local) # i'm a bit superstious on this
  return(g_local) # these nodes are the best of the best of the best, sir!
}

# return only the top N nodes - based on $key. may return less than N due to the removal
# of orphaned vertices
cutnodes <- function(g_local, tocut) {
  tokeep <- length(V(g_local)$key) - tocut
  if (tokeep>0) {
    g_local <- delete.vertices(g_local, order(V(g_local)$key)[1:tokeep])
  }
  g_local <- mysimplify(g_local)
  return(g_local) # these nodes are the best of the best of the best, sir!
}

# return 0 if "a" is a person, 1 if it's a mailing list.  "a" can be a vector.
# d is a directory. any filenames in "d" are considered mailing lists. use
# 0 and 1 and not T and F on purpose (json!)
isperson <- function(a, d) {
  return (ifelse(a %in% dir(d),0,1))
}

# get rid of any vertices without edges
mysimplify <- function(g_local) {
# some update or another of R or graph module made this not work anymore. :/
# keith
# Mon Jan 27 16:08:18 PST 2014
#  g_local <- delete.vertices(g_local, 0)
  g_local <- delete.vertices(g_local, (which(degree(g_local, mode="all", loops=FALSE)<1)))
  g_local <- simplify(g_local)
  return(g_local)
}
