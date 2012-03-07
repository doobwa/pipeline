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

# For each method
for (i in 1:length(methods)) {
  method <- methods[[i]]

  # For each set of arguments for the given method (which are identified by the method's "id").
  ids <- ifelse(is.null(opts$id), 0:(length(method$args)-1), opts$id)
  for (id in ids) {

    # For each dataset we will apply the method to.  If user specifies "all", use all the datasets corresponding to this method in the config file.
    datasets <- ifelse(opts$dataset == "all",
                       config$dataset[method$data],
                       config$dataset[opts$dataset])
    names(datasets) <- ifelse(opts$dataset == "all",
                              method$data,opts$dataset)
    for (d in 1:length(datasets)) {
      dataset <- datasets[[d]]

      # For each split
      for (split in splits) {
        js <- list.files(paste("splits/",split,sep=""))
        for (j in js) {
          # Each method does training and prediction in the same call. So, start writing to both train and test pipes (in bg processes), then launch the command.

          prog <- names(methods)[i]
          desc <- paste(prog,id,names(datasets)[d],sep="_")
          coms <- c()
          
          pipe.path <- paste("splits/",split,"/",j,sep="")
          pipe.base <- paste(desc,sep="_") # Should be unique to this particular run.
          train.pipe <- paste(pipe.path,"/",pipe.base,".train",sep="")
          test.pipe <- paste(pipe.path,"/",pipe.base,".test",sep="")
        
          # Handle the "full" split separately
          train.features <- paste("splits/",split,"/",j,"/train/",dataset$features,sep="",collapse=" ")
          if (split == "full") {  # evaluate training set instead of test set
            test.features <- paste("splits/full/",j,"/train/",dataset$features,sep="",collapse=" ")
          } else {
            test.features <- paste("splits/",split,"/",j,"/test/",dataset$features,sep="",collapse=" ")     
          }
          coms <- c(coms, paste("mkfifo ",train.pipe,sep=""))
          coms <- c(coms, paste("mkfifo ",test.pipe,sep=""))

          # TODO: The way features are glued together should depend on whether the method or features are dense or sparse
          coms <- c(coms, paste("paste -d , ",train.features," >",train.pipe," &",sep=""))
          coms <- c(coms, paste("paste -d , ",test.features," >",test.pipe," &",sep=""))

          predictions.file <- paste("predictions/",split,"/",j,"/test/",desc,sep="")
          log.file <- paste("logs/",split,"/",j,"/test/",desc,sep="")
          coms <- c(coms, paste("./pipeline/methods/",prog,"/",prog," --train ",train.pipe," --test ",test.pipe," --predictions ",predictions.file," --log ",log.file," --id ",id,sep=""))

          coms <- c(coms, paste("rm ",train.pipe,sep=""))
          coms <- c(coms, paste("rm ",test.pipe,sep=""))

          # TODO: Handle "full" dataset separately?
          for (m in dataset$metric) {
            coms <- c(coms, paste("./pipeline/eval --predictions ",predictions.file," --truth splits/",split,"/",j,"/test/response"," --metric ",m," --logfile results.csv --entry '",names(datasets)[d],",",split,",",j,",",prog,",",id,"'",sep=""))
          }
          
          # Group all commands into a single ;-separated string to ensure they 
          # end up on the same server and are executed sequentially.
          commands <- paste(coms,collapse="; ")
          write(commands,file="queue",append=TRUE)
        }
      }
    }
  }
}
