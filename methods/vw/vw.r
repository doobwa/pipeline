#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--split", help=""),
  make_option("--learning_rate", default=".01",help=""),
  make_option("--rank", default="3",help=""),
  make_option("--l1", default=".001",help=""),
  make_option("--l2", default=".001",help="")
  )
parser <- OptionParser(usage = "%prog [options] file", option_list=option_list)
opts   <- parse_args(OptionParser(option_list=option_list))

desc <- paste("vw",opts$learning_rate,opts$rank,opts$l1,opts$l2,sep="_")
train.file <- paste("data/",opts$split,"/train.vw",sep="")
test.file  <- paste("data/",opts$split,"/test.vw",sep="")
prediction.file <- paste("predictions/",opts$split,"/test/",desc,".txt",sep="")
log.file <- paste("logs/",opts$split,"/test/",desc,".txt",sep="")
cache.file <- paste("logs/",opts$split,"/test/",desc,".cache",sep="")

command1 <- paste("./pipeline/methods/vw/vw -d ",train.file," --max_prediction .99 --min_prediction .01 -b 22 -q uq --rank ",opts$rank," --learning_rate ",opts$learning_rate," -c --passes 2 --l1 ",opts$l1," --l2 ",opts$l2," --sort_features -f ",log.file,sep="")
command2 <- paste("./pipeline/methods/vw/vw -d ",test.file," --max_prediction .99 --min_prediction .01 -b 22 -q uq --rank ",opts$rank," --learning_rate ",opts$learning_rate," -c --passes 1 --l1 ",opts$l1," --l2 ",opts$l2," --sort_features -i ",log.file," -t -p ",prediction.file,sep="")

system(paste(command1,command2,sep=";"))

#opts=list(split=2,learning_rate=.01,rank=3,l1=.001,l2=.001)

./pipeline/methods/vw/vw -d data/2/train.vw --max_prediction .99 --min_prediction .01 -b 22 -q uq --rank 3 --learning_rate 0.01 --cache_file logs/2/test/vw_0.01_3_0.001_0.001.cache --passes 2 --l1 0.001 --l2 0.001 --sort_features -f logs/2/test/vw_0.01_3_0.001_0.001.txt &
./pipeline/methods/vw/vw -d data/2/train.vw --max_prediction .99 --min_prediction .01 -b 22 -q uq --rank 3 --learning_rate 0.01 --cache_file logs/2/test/vw_0.01_3_0.01_0.01.cache --passes 2 --l1 0.01 --l2 0.01 --sort_features -f logs/2/test/vw_0.01_3_0.01_0.01.txt &
./pipeline/methods/vw/vw -d data/2/train.vw --max_prediction .99 --min_prediction .01 -b 22 -q uq --rank 3 --learning_rate 0.01 --cache_file logs/2/test/vw_0.01_3_0.1_0.1.cache --passes 2 --l1 0.1 --l2 0.1 --sort_features -f logs/2/test/vw_0.01_3_0.1_0.1.txt