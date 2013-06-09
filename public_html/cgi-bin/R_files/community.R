#
# kjolley
# split from main.R
# Sun Apr 21 18:18:01 PDT 2013
#
communitycenter <- function(g, vfile, efile, cfile, xfile) {

  simplify(g)
  # create a nodes file with just the node names in it
  write.table(V(g)$name, file=vfile, col.names=F, row.names=F, quote=F)

  # create an edges table with "from" "to" "weight" columns
  write.table(
    subset(get.data.frame(g),select=c(from, to, weight)),
    file=efile, col.names=F, row.names=F, quote=F)

  # run the community finder - it's much faster than R
  system(paste("community/makecommunity.sh", vfile, efile, cfile, xfile))

  # i obviously missed something on how to merge info into the vertices oh well.
  vertices <- data.frame(read.delim(cfile, header=TRUE))

  # translate communities to 1,2,3...
  vertices$community <- as.numeric(factor(vertices$community))

  #merge the community info back into the graph
  vertices <- merge(vertices, get.data.frame(g, what="vertices"), by="name")
  edges <- get.data.frame(g, what="edges") # uh - i don't know why i did this
  g <- graph.data.frame(edges, directed=T, vertices=vertices)

  # read in the modularity
  commdat <- data.frame(read.delim(xfile, header=TRUE))
  g$modularity <- commdat$modularity

  return(g)
}
