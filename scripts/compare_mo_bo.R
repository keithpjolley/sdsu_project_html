#
# kjolley
# Sun May 19 19:43:24 PDT 2013
#
# mysql> use ph;
# mysql> select source, target, sum(bytes_out) as bo, sum(messages_out) as mo from edge_message where source > 0 and target > 0 group by source, target into outfile '/tmp/edges.txt';
#
library(igraph)
library(ggplot2)
library(scales)

d           <- read.csv(file="/tmp/edges.txt", head=FALSE, sep='\t')
names(d)    <- c("source", "target", "bytes", "messages")
d           <- d[d$bytes    > 0, ]
d           <- d[d$messages > 0, ]

d$weight    <- d$bytes
g           <- graph.data.frame(d, directed=TRUE)
g           <- simplify(g)
pr_bytes    <- page.rank(g)$vector

d$weight    <- d$messages
g           <- graph.data.frame(d, directed=TRUE)
g           <- simplify(g)
pr_messages <- page.rank(g)$vector

pr          <- data.frame(messages=pr_messages, bytes=pr_bytes)

p           <- ggplot(data=pr, aes(x=messages, y=bytes))
p           <- p + coord_fixed(ratio=1)
p           <- p + geom_point()
p           <- p + stat_smooth(method="glm", se=T, col="grey")
p           <- p + scale_y_continuous(name="PageRank - bytes sent",    labels=comma) 
p           <- p + scale_x_continuous(name="PageRank - message count", labels=comma) 
p           <- p + ggtitle("Comparison of PageRank by 'bytes sent' v. 'message count'")

png(file="corr_bo_mo.png",  bg="white", res=600, width=5000, height=5000)
print(p)
dev.off()
