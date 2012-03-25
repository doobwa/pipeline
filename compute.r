#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("rjson"))
option_list <- list(
  make_option("--feature", help="")
  )
parser <- OptionParser(usage = "%prog [options]", option_list=option_list)
opts   <- parse_args(OptionParser(option_list=option_list))

config <- fromJSON(,"config.json")

if (is.null(opts$feature) | opts$feature=="all") {
  opts$feature <- list.files("features/")
}

splits <- list.files("splits/")
for (s in splits) {
  subsplits <- list.files(paste("splits/",s,sep=""))
  for (j in subsplits) {
    for (f in opts$feature) {
      for (k in c("train","test")) {
        infile <- paste("splits/",s,"/",j,"/",k,"/data",sep="")
        outfile <- paste("splits/",s,"/",j,"/",k,"/",f,sep="")
        command <- paste("cd ",config$path,"; ./features/",f," --infile ",infile," --outfile ",outfile,sep="") 
        write(command,file="queue",append=TRUE)
      }
    }
   # TODO: Sanity check that all feature files within a split have the same length
   # sapply(list.files(paste("splits/",s,"/",j,sep="")),function(f) {
   #   as.numeric(read.table(pipe(paste('wc -l',f)))[1])
   #  })
   # }
  }
}


cat("Commands written to queue.\n")
