#
# kjolley
# Sat Jun 15 07:15:52 PDT 2013
#
#
# this function draws the distribution plot
# expects a graph, an output png file path, and a path to the vertex attribute file
#
#
distro<-function(g_local, thepng, afile) {
  t<-read.delim(afile, header=FALSE, comment.char="#", fill=F, sep=";")
  names(t) <- c("name", "attrib", "desc")
  t<-t[t$attrib=="display_name",]
  t$attrib<-NULL
  df<-get.data.frame(g_local, what="vertices")
  attribs <-c( 'pr', 'evcent', 'betweenness_vertex', 'closeness_in', 'closeness_out',
            'degree', 'graph_strength_in', 'graph_strength_out', 'graph_strength_tot', 'lcc')
  png(filename=thepng, bg="white", width=800, height=1600)
  par(mfrow=c(4,3))
  for (i in attribs ) {
    d<-df[[i]]
    d<-d[!is.na(d)]
    d<-d[!is.infinite(d)]
    title<-as.character(t[t$name==i,]$desc)
    hist(d, breaks=seq(min(d), max(d), (max(d)-min(d))/20), main=title,
        xlab=NULL, probability=TRUE, col="grey", border="white")
    dens<-density(d)
    lines(dens, col="red")
  }

  attribs <- c('community')
  # plot "isperson" if there are people AND mailinglists
  if (length(unique(V(g_local)$isperson))>1) attribs <- c(attribs, 'isperson')
  for (i in attribs) {
    cat(i,file="/dev/stderr")
    d<-df[[i]]
    names <- NULL
    if (i == "isperson") names <- c("List", "Person")
    title<-as.character(t[t$name==i,]$desc)
    barplot(table(d),  main=title, col="grey", border="white", names.arg=names)
  }
  dev.off()
}
