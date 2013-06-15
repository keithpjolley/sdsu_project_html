##
#
# kjolley
# Sat Apr 20 15:10:48 PDT 2013
#
##
if (interactive()) cat("loading libraries\n")
library(igraph)
library(data.table)
library(RColorBrewer)

# these have some functions in them
if (interactive()) cat("sourcing my R files\n")
source("R_files/community.R")
source("R_files/json.R")
source("R_files/misc.R")
source("R_files/metric.R")
source("R_files/distro.R")

# color scheme
mypalette <- brewer.pal(12, "Paired")

# maillistdir helps us figure out which targets are lists and which are people
#maillistdir<-"mailing-lists"  # get this from the caller instead

# read in our table of unique edges
if (interactive()) cat(paste("R: Reading input table:", rfile, "\n"))
g <- getgraph(rfile)
if (interactive()) cat(paste("R: Start: This graph has", length(E(g)$weight), "edges and", length(V(g)), "vertices\n"))

# we use this KEY to filter out vertices.
if (interactive()) cat("R: creating key metric for graph (eigenvector centrality).\n")
#V(g)$key <- page.rank(g)$vector   # key off of pagerank?  evc seems to work better.
V(g)$key <- evcent(g)$vector

# get rid of some of the noise
N <- 25
if (length(V(g)$key) > 100+N) {
  if (interactive()) cat(paste("R: cutting out the bottom", N, "percent page.ranked nodes.  noise reduction\n"))
  g <- mibnodes(g, N)
  if (interactive()) cat(paste("R: mibnodes: This graph has", length(E(g)$weight), "edges and", length(V(g)), "vertices\n"))
}

# don't allow more than this many nodes on the screen at once
N <- 750
if (interactive()) cat(paste("R: cutting out all but the top", N, "page.ranked nodes.  noise reduction\n"))
g <- cutnodes(g, N)
if (interactive()) cat(paste("R: cutnodes: This graph has", length(E(g)$weight), "edges and", length(V(g)), "vertices\n"))

# community finding in R is SLOW. go outside.
if (interactive()) cat("R: Running external community analysis.\n")
g <- communitycenter(g, vfile, efile, cfile, xfile)

# get some stats on this network
if (interactive()) cat(paste("R: getting some stats on this network.\n"))
g <- metric(g, mfile)
if (interactive()) cat(paste("R: This graph has", length(E(g)$weight), "edges and", length(V(g)), "vertices\n"))

# follow the naming convention of D3 
if (interactive()) cat(paste("R: Saving JSON file:", jfile, "\n"))
json <- graphToJSON(g, mypalette)
cat(json, file=jfile, append=FALSE)

# make the png distribution plot
if (interactive()) cat(paste("R: Saving PNG file:", pfile, "\n"))
distro(g, pfile, afile, mypalette)
