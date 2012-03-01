#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--split",help=""),
  make_option("--distribution",default="bernoulli",help=""),
  make_option("--ntrees",default=500,help=""),
  make_option("--final_trees",default=300,help=""),
  make_option("--shrinkage",default=.005,help=""),
  make_option("--interaction_depth",default=4,help=""),
  make_option("--bag_fraction",default=.5,help=""),
  make_option("--train_fraction",default=.5,help=""),
  make_option("--min_obs_per_node",default=10,help=""),
  make_option("--keep_data",default=FALSE,help=""),
  make_option("--cvfolds",default=5,help=""),
  make_option("--verbose",default=TRUE,help="")
  )
parser <- OptionParser(usage = "%prog [options] file", option_list=option_list)
opts   <- parse_args(OptionParser(option_list=option_list))

desc <- paste("gbm",opts$distribution,opts$ntrees,opts$shrinkage,opts$interaction_depth,sep="_")

train.x <- read.csv(paste("data/",opts$split,"/train.features.csv",sep=""),row.names=1)
train.y <- read.csv(paste("data/",opts$split,"/train.response.csv",sep=""),row.names=1)
test.x <- read.csv(paste("data/",opts$split,"/test.features.csv",sep=""),row.names=1)
train.x <- as.matrix(train.x)
train.y <- as.matrix(train.y)
test.x <- as.matrix(test.x)

prediction.file <- paste("predictions/",opts$split,"/test/",desc,".txt",sep="")
log.file <- paste("logs/",opts$split,"/test/",desc,".rdata",sep="")

#opts=list(split=1,distribution="bernoulli",ntrees=500,final_trees=300,shrinkage=.005,interaction_depth=4,bag_fraction=.5,train_fraction=.5,min_obs_per_node=10,keep_data=FALSE,cvfolds=5,verbose=TRUE)

# See vignette on use.
# Prediction (and fitting?) requires converting covariates to full matrix, so tread carefully.
require(gbm)

fit <- gbm.fit(train.x,train.y,
    distribution=opts$distribution,
    n.trees=opts$ntrees,
    shrinkage=opts$shrinkage,
    interaction.depth=opts$interaction_depth,
    bag.fraction =opts$bag_fraction,
    train.fraction =opts$train_fraction,
    n.minobsinnode =opts$min_obs_per_node,
    var.names = colnames(train.x),
    keep.data=opts$keep_data,
    verbose=opts$verbose)

best.iter <- gbm.perf(fit,method="OOB")
save(fit,best.iter,file=log.file)

yhat <- predict(fit,newdata=test.x,n.trees=best.iter,type="response")
write(paste(yhat,collapse="\n"),file=prediction.file)
