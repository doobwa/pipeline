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
  ids <- ifelse(is.null(opts$id), 0:(length(method$args)-1), opts$id)
  for (id in ids) {
    datasets <- ifelse(opts$dataset == "all",
                       config$dataset[method$data],
                       config$dataset[opts$dataset])
    for (dataset in datasets) {
      for (split in splits) {
        js <- list.files(paste("splits/",split,sep=""))
        for (j in js) {
          # TODO: make train and test using named pipe with all features for this dataset.  Use `paste -d , [space-separated list of feature files]` to combine them.
          
          coms <- c()
          features <- paste("splits/",split,"/",j,"/train/",dataset$features,sep="",collapse=" ")
          coms <- c(coms,paste("paste -d ,",features,"> train.tmp"))
          features <- paste("splits/",split,"/",j,"/test/",dataset$features,sep="",collapse=" ")
          coms <- c(coms,paste("paste -d ,",features,"> test.tmp"))
          
          # TODO: Improve handling of method arguments
          prog <- names(methods)[i]
          desc <- paste(prog,id,sep="_")  # TODO: Need to fix description here
          
          predictions.file <- paste("predictions/",split,"/",j,"/test/",desc,sep="")
          log.file <- paste("logs/",split,"/",j,"/test/",desc,sep="")
          
          coms <- c(coms,paste("./pipeline/methods/",prog,"/",prog," --train train.tmp --test test.tmp --predictions ",predictions.file," --log ",log.file,sep=""))
          
          for (m in dataset$metric) {
            coms <- c(coms,paste("./pipeline/eval --predictions ",predictions.file," --truth splits/",split,"/",j,"/test/response"," --metric ",m," --logfile results --entry '",split,",",j,",",prog,",",id,"'",sep=""))
          }
            
          commands <- paste(coms,sep=";\n")
          write(commands,file="queue",append=TRUE)
        }
      }
    }
  }
}