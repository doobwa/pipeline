#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--split", 
              help=""),
  make_option("--cache", default=FALSE,
              help="Use previously created files."),
  make_option(c("-i","--iterations"), default=5,
              help=""),
  make_option(c("-r","--regularization"), default="0,1,10",
              help=""),
  make_option(c("-t","--task"), default="r",
              help=""),
  make_option("--test", default=TRUE,
              help=""),
  make_option(c("-d","--dimensions"), default="1,1,50",
              help=""),
  make_option("--learnrate", default=".1",
              help=""),
  make_option(c("-m","--method"), default="als",
              help="")
)
parser <- OptionParser(usage = "%prog [options] file", option_list=option_list)
opts   <- parse_args(OptionParser(option_list=option_list))

r <- gsub(",",".",opts$regularization)
d <- gsub(",",".",opts$dimensions)
outfile <- paste("predictions/",opts$split,"/test/fm.",r,".",d,".",opts$method,".",opts$task,".txt",sep="")
logfile <- paste("logs/",opts$split,"/test/fm.",r,".",d,".",opts$method,".",opts$task,".txt",sep="")

if (opts$test) {
  testfile <- paste("--test data/",opts$split,"/test.fm",sep="")
} else {
  testfile <- paste("--test data/",opts$split,"/train.fm",sep="")
} 

command <- paste("./pipeline/methods/fm/bin/libFM --train data/",opts$split,"/train.fm ",testfile," --dim ",opts$dim," --iter ",opts$iter," --regular ",opts$regularization," --task ",opts$task," --out ",outfile," --verbosity 1 --rlog ",logfile," --method ",opts$method," --learn_rate ",opts$learnrate,sep="")

system(command)