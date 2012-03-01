
baseline <- read.csv("submissions/benchmark_lmer_submission.csv")[,2]

ys <- list()
for (i in 1:5) {
  load(paste("working.data/",i,".rdata",sep=""))
  #ys[[i]] <- read.csv(paste("data/",i,"/test.response.csv",sep=""))
  ys[[i]] <- d$test$y
}
save(ys,file="responses.rdata")


collect.results <- function(ys,yhats,metric){
  res <- list()
  for (i in 1:5) {
    res[[i]] <- list()
    for (j in names(yhats[[i]])) {
      res[[i]][[j]] <- metric(ys[[i]],yhats[[i]][[j]])
    }
  }
  return(melt(res))
}
collect.jittered.results <- function(ys,yhats,metric){
  res <- list()
  for (i in 1:5) {
    res[[i]] <- list()
    for (j in names(yhats[[i]])) {
      res[[i]][[j]] <- list()
      for (k in 1:10) {
        ix <- sample(1:length(ys[[i]]),replace=TRUE)
        res[[i]][[j]][[k]] <- metric(ys[[i]][ix],yhats[[i]][[j]][ix])
      }
    }
  }
  return(melt(res))
}
fmname2args <- function(res) {
  ds <- lapply(res$L2,function(x) strsplit(x,"\\.")[[1]])
  ds <- do.call(rbind,ds)
  ds <- ds[,c(-1,-ncol(ds))]
  colnames(ds) <- c(paste("reg",0:2,sep="_"),paste("K",0:2,sep="_"),"method","task")
  ds <- as.data.frame(ds)
  cbind(res,ds)
}
vwname2args <- function(res) {
  ds <- lapply(res$L2,function(x) strsplit(x,"_")[[1]])
  ds <- do.call(rbind,ds)
  ds <- ds[,c(-1,-ncol(ds))]
  colnames(ds) <- c(paste("reg",0:2,sep="_"),paste("K",0:2,sep="_"),"method","task")
  ds <- as.data.frame(ds)
  cbind(res,ds)
}

# Collection predictions (only FM right now)
yhats <- list()
folders <- paste("predictions/",1:5,"/test",sep="")
for (folder in folders) {
  for (f in list.files(folder)) {
    cat(folder,"/",f,": ")
    if (grepl("fm",f)) yhats[[folder]][[f]] <- scan(paste(folder,"/",f,sep=""))
  }
}
tmp <- yhats
for (i in 1:length(yhats)) {
  for (j in 1:length(yhats[[i]])) {
    if  (length(yhats[[folder]][[f]]) != length(ys[[i]])) yhats[[i]][[j]] <- NULL
   # if (!grepl("fm",f)) yhats[[i]][[j]] <- NULL
  }
}
res <- collect.results(ys,yhats,CappedBinomialDeviance)
resj <- collect.jittered.results(ys,yhats,CappedBinomialDeviance)
save(res,resj,file="results.als.rdata")

load("results.als.rdata")
res.als <- fmname2args(resj[grep("fm",resj$L2),])
qplot(value,factor(L2),data=subset(res.als,method=="als"),colour=factor(reg_2)) + facet_grid(L1~.) + theme_bw() + labs(y="",colour="regularization")

res.als$reg_2 <- as.numeric(as.character(res.als$reg_2))
tmp <- subset(res.als,method=="als" & reg_2 > 10)
qplot(value,factor(L2),data=tmp,colour=factor(reg_2)) + facet_grid(L1~.) + theme_bw() + labs(y="",colour="regularization")

res.vw <- res[grep("vw",res$L2),]
res.gbm <- res[grep("gbm",res$L2),]

qplot(value,factor(L2),data=subset(res,method=="vw"))

qplot(value,factor(L2),data=subset(res,method=="sgd"),colour=factor(reg_2)) + facet_grid(L1~.) + theme_bw() + labs(y="",colour="regularization")

ensemble.mean <- function(files) {
  yhats <- lapply(files,function(f) scan(f))
  names(yhats) <- 1:length(yhats)
  df <- data.frame(yhats)
  rowMeans(df)
}
