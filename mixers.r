
##' For a given method, split, and set of features, return the command needed to
##' 1) create train and test pipes
##' 2) create locations for prediction files and log files
##' 3) fit the method
##' 4) remove the pipes
##' Also return the locations of the prediction files.
##' @param desc description for this method
##' @param features list of features for this dataset
##' @param prog name of method
##' @param split name of split (e.g. 5fold)
##' @param j split number
##' @param aux filename of auxilary feature needed for this mixer
##' @return list: command, prediction.train.fi
mixer_default <- function(desc,features,prog,split,j,aux=NULL) {
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
  
  return(list(command=coms,prediction.train.file,prediction.test.file))
}

##' This mixer creates commands needed to fit a method to different subsections of a given dataset.  To do this, the mixer requires an auxilary feature (read in from the file or pipe aux) containing a vector of integers with the same length as the number of observations in the provided split.
##' @param aux filename (or location of pipe) 
mixer_byaux <- function(desc,features,prog,split,j,aux) {
  
}
