#
# kjolley
# Sat Jun 15 07:15:52 PDT 2013
#
#
# this function draws the distribution plot
# expects a graph, an output png file path, and a path to the vertex attribute file
#
#
distro<-function(g_local, pfile, afile, mypalette) {
  df<-get.data.frame(g_local, what="vertices")

  t<-read.delim(afile, header=FALSE, comment.char="#", fill=F, sep=";")
  names(t) <- c("name", "attrib", "desc")
  dn<-t[t$attrib=="display_name",]
  dn$attrib<-NULL
  xl<-t[t$attrib=="xlab",]
  xl$attrib<-NULL
  yl<-t[t$attrib=="ylab",]
  yl$attrib<-NULL
  attribs <-c( 'pr', 'evcent', 'betweenness_vertex', 'closeness_in', 'closeness_out',
            'degree', 'graph_strength_in', 'graph_strength_out', 'graph_strength_tot', 'lcc')
#  png(filename=pfile, bg="white", width=1400, height=1400)
#  par(mfrow=c(4,3))
  for (i in attribs ) {
    d<-df[[i]]
    d<-d[!is.na(d)]
    d<-d[!is.infinite(d)]
    title<-as.character(dn[dn$name==i,]$desc)
    p<-sprintf("/tmp/foo/%s.pdf", i)
    pdf(file=p, bg="white")
    hist(d, breaks=50, main=title, xlab=xl[xl$name==i,]$desc, ylab=yl[yl$name==i,]$desc,
        probability=FALSE, col="grey", border="white")
#    hist(d, y=(..count../sum(..count..)), breaks=seq(min(d), max(d), (max(d)-min(d))/30), main=title,
#        xlab=xl[xl$name==i,]$desc, ylab=yl[yl$name==i,]$desc, probability=FALSE, col="grey", border="white")
#    Density is a material property defined as mass per unit volume, which obviously does not apply here. 
#    dens<-density(d)
#    lines(dens, col="red")
#    ggplot no comprende par. :/
#    p<-ggplot(as.data.frame(d))
#    p<-p+geom_histogram(aes(x=d,y=..count../sum(..count..)), fill="grey",colour="darkgrey", binwidth=(max(d)-min(d))/50)
#    p<-p+ggtitle(title)
#    p<-p+xlab(xl[xl$name==i,]$desc)
#    p<-p+ylab(yl[yl$name==i,]$desc)
#    p<-p+theme_bw()
#    print(p)
     dev.off()
  }

  attribs <- c('community')
  # plot "isperson" if there are people AND mailinglists
  if (length(unique(V(g_local)$isperson))>1) attribs <- c(attribs, 'isperson')
  for (i in attribs) {
    d<-df[[i]]
    title<-as.character(dn[dn$name==i,]$desc)
    xlab<-as.character(xl[xl$name==i,]$desc)
    ylab<-as.character(yl[yl$name==i,]$desc)
    names  <- NULL
    colors <- "grey"
    if (i == "community") {
      colors <- mypalette[(sort(unique(V(g_local)$community))-1)%%12+1]
    } else if (i == "isperson") {
      names <- c("List", "Person")
    }
    p<-sprintf("/tmp/foo/%s.pdf",i)
    pdf(file=p, bg="white")
    barplot(table(d), main=title, border="white", xlab=xlab, ylab=ylab, names.arg=names, col=colors)
    dev.off()
  }
  dev.off()
}
