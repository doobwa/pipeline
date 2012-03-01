training <- read.csv("data/training.csv", header=TRUE, comment.char = "", colClasses = c('integer','integer','integer','integer','integer','integer','integer','integer','character','character','character','character','integer','integer','integer','NULL','integer'))
training <- training[training$outcome == 1 | training$outcome == 2,]
#valid.training <- read.csv("data/valid_training.csv", header=TRUE, as.is=TRUE)
valid.training <- read.csv("data/valid_training.csv", header=TRUE, comment.char = "", colClasses = c('integer','integer','integer','integer','integer','integer','integer','integer','character','character','character','character','integer','integer','integer','NULL','integer'))
valid.test <- read.csv("data/valid_test.csv", header=TRUE, as.is=TRUE)
test <- read.csv("data/test.csv", header=TRUE, as.is=TRUE)

fixup <- function(d) {
  x <- d[,c("user_id","question_id","track_name","subtrack_name","game_type","question_set_id")]
  x <- do.call(cbind,x)
  if ("correct" %in% names(d))
    y <- d[,"correct"]
  else
    y <- rep(0,nrow(d))
  
  # Get waiting time until answer: Bin into (5,10,30,60,more) seconds
  waiting <- strptime(d$answered_at,format="%Y-%m-%d %H:%M:%S") - strptime(d$round_started_at,format="%Y-%m-%d %H:%M:%S")
  waiting <- cut(as.numeric(waiting),breaks=c(-Inf,0,5,10,30,60,120,300,Inf))
  waiting <- as.numeric(waiting)
  ix <- which(is.na(waiting))
  if (length(ix)>0) waiting[ix] <- 1
  x <- cbind(x,waiting=as.numeric(waiting))
  
  # TODO: Compute number of previously answered questions per user/
  return(list(y=y,x=x))
}

convertRow <- function(y,x,dims) {
  right <- x + b
  ans <- paste(paste(right,1,sep=":"),collapse=" ")
  return(paste(y,ans,sep=" "))
}

convertMatrix <- function(d,outfile,dims) {
  options(scipen=7)  # don't allow scientific notation when converting to characters
  D <- length(dims)
  b <- c(0,cumsum(dims[-D]))
  b <- matrix(b,nr=nrow(d$x),nc=D,byrow=TRUE)
  b <- d$x + b
  for (j in 1:D) {
    print(j)
    b[,j]  <- paste(b[,j],1,sep=":")
  }
  a <- cbind(y=d$y,b)
  g <- sapply(1:nrow(a),function(i)  paste(a[i,],collapse=" "))
  gall <- paste(g,collapse="\n")
  write(gall,outfile)
}

test_that("convert to libsvm format",{
  # first row of trianing set
  y <- 0
  x <- c(85818,5560,5,14)
  dims <- c(179104,6045,8,15) + 1  # num unique values=max value + 1
  right <- c(85818,dims[1]+5560,dims[1]+dims[2]+5,dims[1]+dims[2]+dims[3]+14)
  ans <- "0 85818:1 184665:1 185156:1 185174:1"
  expect_that(convertRow(y,x,dims),equals(ans))
})

convertDataset <- function(d,outfile,dims) {
  write(convertRow(d$y[1],d$x[1,],dims),outfile)
  pb <- txtProgressBar(min=0,max=nrow(d$x),style=3)
  for (i in 2:nrow(d$x)) {
    setTxtProgressBar(pb,i)
    write(convertRow(d$y[i],d$x[i,],dims),outfile,append=TRUE)
  }
  close(pb)
}

training <- fixup(training)
valid.training <- fixup(valid.training)
valid.test <- fixup(valid.test)
test <- fixup(test)
save(training,file="working.data/training.rdata")
save(valid.training,file="working.data/valid.training.rdata")
save(valid.test,file="working.data/valid.test.rdata")
save(test,file="working.data/test.rdata")
#save(training,valid.training,valid.test,test,file="working.data/all.rdata")

dims <- apply(training$x,2,max)

convertMatrix(training,"data/training.sp.txt",dims)
convertMatrix(valid.training,"data/valid.training.sp.txt",dims)
convertMatrix(valid.test,"data/valid.test.sp.txt",dims)
convertMatrix(test,"data/test.sp.txt",dims)

# convertDataset(training,"data/training.sp.txt",dims)
# convertDataset(valid,"data/valid.sp.txt",dims)
# convertDataset(test,"data/test.sp.txt",dims)
