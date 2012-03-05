#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--train", help=""),
  make_option("--test", help=""),
  make_option("--predictions", help=""),
  make_option("--log", help="")
)
opts   <- parse_args(OptionParser(option_list=option_list))

desc <- paste("glm",opts,sep="_")
outfile <- paste("predictions/",opts$split,"/test/",desc,sep="")
logfile <- paste("logs/",opts$split,"/test/",desc,sep="")

train <- read.csv()
fit <- glm(y ~ .,family="binomial")
yhat <- predict(fit,type="response",data=test)

# TODO: Write to file 
