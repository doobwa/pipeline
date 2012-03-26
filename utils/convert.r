vw2edgelist <- function(lines) {
  ds <- mclapply(1:length(lines),function(i) {
    r <- strsplit(lines[i],"\\|")[[1]]
    a <- gsub(" ","\n",r[2])
    a <- gsub(":",",",a)
    a <- as.matrix(read.csv(textConnection(a),header=F))
    cbind(i,a)
  })
  do.call(rbind,ds)
}
vw2response <- function(lines) {
  unlist(mclapply(1:length(lines),function(i) {
    r <- strsplit(lines[i],"\\|")[[1]]
    as.numeric(r[1])
  }))
}

## convertmat2libsvm <- function(d,outfile,dims) {
##   options(scipen=7)  # don't allow scientific notation when converting to characters
##   D <- length(dims)
##   cat("pasting each row\n")
##   b <- mclapply(1:D,function(j)  paste(j,b[,j],sep=":"))
##   b <- do.call(cbind,b)
##   a <- cbind(y=d$y,b)
##   cat("pasting each column\n")
##   g <- unlist(mclapply(1:nrow(a),function(i)  paste(a[i,],collapse=" ")))
##   cat("collapsing\n")
##   gall <- paste(g,collapse="\n")
##   cat("writing to file\n")
##   write(gall,outfile)
## }

## convert2libsvm <- function(d,outfile,dims) {
##   write(convertrow2libsvm(d$y[1],d$x[1,],dims),outfile)
##   pb <- txtProgressBar(min=0,max=nrow(d$x),style=3)
##   for (i in 2:nrow(d$x)) {
##     setTxtProgressBar(pb,i)
##     write(convertrow2libsvm(d$y[i],d$x[i,],dims),outfile,append=TRUE)
##   }
##   close(pb)
## }
