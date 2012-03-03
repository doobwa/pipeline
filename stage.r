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
          # cat(names(methods)[i],arg,dataset,split,j,"\n")
          prog <- names(methods)[i]
          entry <- paste("./pipeline/methods/",prog,"/",prog," ",arg," --dataset ",dataset," ...(MORE HERE)",sep="")
          write(entry,file="queue",append=TRUE)
        }
      }
    }
  }
}