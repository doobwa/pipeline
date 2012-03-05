#!/usr/bin/env Rscript

suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("rjson"))

option_list <- list(
  make_option("--method",  default="all", help=""),
  make_option("--dataset", default="all", help=""),
  make_option("--id", help="")
)
parser <- OptionParser(usage = "%prog [options] datafile", option_list=option_list)
opts <- parse_args(parser, positional_arguments = TRUE)$options

config <- fromJSON(,"config.json")
splits <- list.files("splits")

if (opts$method == "all") {
  methods <- config$method
} else {
  methods <- config$method[opts$method]
  names(methods) <- opts$method
}

for (i in 1:length(methods)) {
  method <- methods[[i]]
  for (arg in method$args) {
    datasets <- ifelse(opts$dataset == "all", method$data,opts$dataset)
    for (dataset in datasets) {
      for (split in splits) {
        js <- list.files(paste("splits/",split,sep=""))
        for (j in js) {
          # TODO: make train and test using named pipe with all features for this dataset.  Use `paste -d , [space-separated list of feature files]` to combine them.
          
          features <- paste("splits/",split,"/",j,"/train/",config$dataset[[dataset]]$features,sep="",collapse=" ")
          command1 <- paste("paste -d ,",features,"> train.tmp")
          features <- paste("splits/",split,"/",j,"/test/",config$dataset[[dataset]]$features,sep="",collapse=" ")
          command2 <- paste("paste -d ,",features,"> test.tmp")
          
          # TODO: Improve handling of method arguments
          prog <- names(methods)[i]
          arg <- gsub("-","",arg)
          arg <- gsub(" ","",arg)
          desc <- paste(prog,arg,sep="_")  # TODO: Need to fix description here
          
          predictions.file <- paste("predictions/",split,"/",j,"/test/",desc,sep="")
          log.file <- paste("logs/",split,"/",j,"/test/",desc,sep="")
          
          command3 <- paste("./pipeline/methods/",prog,"/",prog," ",arg," --train train.tmp --test test.tmp --predictions ",predictions.file," --log ",log.file,sep="")
          commands <- paste(command1,command2,command3,sep=";\n")
          write(commands,file="queue",append=TRUE)
        }
      }
    }
  }
}