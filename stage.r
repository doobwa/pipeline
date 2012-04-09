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

# Load mixer functions
source("pipeline/mixers.r")

# Read configuration file
config <- fromJSON(,"config.json")
splits <- list.files("splits")

# Get method
method.id <- NULL
if (opts$method == "all") {
  methods <- config$method
} else {
  method.arg <- strsplit(opts$method, ":")[[1]]
  method.name <- method.arg[1]
  if (length(method.arg) > 1) {
    method.id <- method.arg[2]
  }
  methods <- config$method[method.name]
  names(methods) <- method.name
}

# For each method
for (i in 1:length(methods)) {
  method <- methods[[i]]

  # For each set of arguments for the given method (which are identified by the method's "id").
  if (is.null(method.id)) {
    ids <- 0:(length(method$args)-1)
  } else {
    ids <- method.id
  }
  for (id in ids) {

    # For each dataset we will apply the method to.  If user specifies "all", use all the datasets corresponding to this method in the config file.
    if (opts$dataset == "all") {
      datasets <- config$dataset[method$data]
      names(datasets) <- method$data
    } else {
      datasets <- config$dataset[opts$dataset]
      names(datasets) <- opts$dataset
    }
    for (d in 1:length(datasets)) {
      dataset <- datasets[[d]]

      # Find out which mixer to use for this data set (and possibly the auxilary file needed for this)
      if (is.null(dataset$mixer)) dataset$mixer <- "default"
      mixer <- switch(dataset$mixer,
                      "default" = mixer_default,
                      "by_aux"  = mixer_byaux)
      aux <- dataset$mixer_aux

      # For each split
      for (split in splits) {
        js <- list.files(paste("splits/",split,sep=""));
        for (j in js) {
          
          # Each method does training and prediction in the same call. So, start writing to both train and test pipes (in bg processes), then launch the command.
          prog <- names(methods)[i]
          desc <- paste(prog,id,names(datasets)[d],sep="_")

          # Get commands needed to create pipes and fit method
          pipe.path <- paste("splits/",split,"/",j,sep="")
          pipe.base <- paste(desc,sep="_") # Should be unique to this particular run.
          train.pipe <- paste(pipe.path,"/",pipe.base,".train",sep="")
          test.pipe <- paste(pipe.path,"/",pipe.base,".test",sep="")
          
          train.features <- paste("splits/",split,"/",j,"/train/",dataset$features,sep="",collapse=" ")
          test.features <- paste("splits/",split,"/",j,"/test/",dataset$features,sep="",collapse=" ") 
          coms <- c(coms, paste("if [ -e ",train.pipe," ]; then ","rm ",train.pipe," ]; fi",sep=""))
          coms <- c(coms, paste("if [ -e ",train.pipe," ]; then ","rm ",train.pipe," ]; fi",sep=""))
          coms <- c(coms, paste("mkfifo ",train.pipe,sep=""))
          coms <- c(coms, paste("mkfifo ",test.pipe,sep=""))

          ## TODO: The way features are glued together should depend on whether the method or features are dense or sparse
          coms <- c(coms, paste("(paste -d , ",train.features," >",train.pipe," &) 2>/dev/null",sep=""))
          coms <- c(coms, paste("(paste -d , ",test.features," >",test.pipe," &) 2>/dev/null",sep=""))

          predictions.train.file <- paste("predictions/",split,"/",j,"/train/",desc,sep="")
          predictions.test.file <- paste("predictions/",split,"/",j,"/test/",desc,sep="")
          log.file <- paste("logs/",split,"/",j,"/test/",desc,sep="")

          create.commands <- coms
          
          fit.commands <- paste("./pipeline/methods/",prog,"/",prog," --train ",train.pipe," --test ",test.pipe," --predictionsTrain ",predictions.train.file," --predictionsTest ",predictions.test.file," --log ",log.file," --id ",id,sep="")

          coms <- c()
          coms <- c(coms, paste("rm ",train.pipe,sep=""))
          coms <- c(coms, paste("rm ",test.pipe,sep=""))

          # Mixer
          ./pipeline/mixer/byaux --train train.pipe --test test.pipe --aux --predictionsTrain predictions.train.file  

          aux.train <- aux.test <- ""
          if (!is.null(dataset$eval_aux)) {
            aux.train <- paste(" --aux ","splits/",split,"/",j,"/train/",dataset$eval_aux,sep="")
            aux.test  <- paste(" --aux ","splits/",split,"/",j,"/test/",dataset$eval_aux,sep="")
          }

          pred_transform <- dataset$pred_transform
          if (!is.null(pred_transform)) {
            raw.train.file <- paste(predictions.train.file,".raw",sep="")
            raw.test.file  <- paste(predictions.test.file,".raw",sep="")
            coms <- c(coms, paste("mv",predictions.train.file,raw.train.file))
            coms <- c(coms, paste("mv",predictions.test.file,raw.test.file))
            coms <- c(coms, paste("scripts/",pred_transform," --infile ",raw.train.file,aux.train," --outfile ",predictions.train.file,sep=""))
            coms <- c(coms, paste("scripts/",pred_transform," --infile ",raw.test.file,aux.test," --outfile ",predictions.test.file,sep=""))
          }

          for (m in dataset$metric) {
            coms <- c(coms, paste("./pipeline/eval --predictions ",predictions.train.file," --truth splits/",split,"/",j,"/train/response",aux.train," --metric ",m," --logfile results.csv --entry '",names(datasets)[d],",",split,",",j,",",prog,",",id,",train'",sep=""))
            coms <- c(coms, paste("./pipeline/eval --predictions ",predictions.test.file," --truth splits/",split,"/",j,"/test/response",aux.test," --metric ",m," --logfile results.csv --entry '",names(datasets)[d],",",split,",",j,",",prog,",",id,",test'",sep=""))
          }

          eval.commands <- coms

          # Save commands needed to create all the pipes and evaluate the prediction files.  Should be useful when fitting models interactively.
          debug.file <- "debug.rdata"
          save(create.commands,fit.commands,eval.commands,prog,train.pipe,test.pipe,predictions.train.file,predictions.test.file,log.file,id,file=debug.file)

          # Group all commands into a single ;-separated string to ensure they 
          # end up on the same server and are executed sequentially.
          commands <- paste(c(create.commands,fit.commands,eval.commands),collapse="; ")
          write(commands,file="queue",append=TRUE)
        }
      }
    }
  }
}

