#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))
option_list <- list(
  make_option("--feature", help="")
  )
parser <- OptionParser(usage = "%prog [options]", option_list=option_list)
opts   <- parse_args(OptionParser(option_list=option_list))

if (is.null(opts$feature) | opts$feature=="all") {
  opts$feature <- list.files("features/")
}

cat("writing:\n")
splits <- list.files("splits/")
for (s in splits) {
  subsplits <- list.files(paste("splits/",s,sep=""))
  for (j in subsplits) {
    for (f in opts$feature) {
      for (k in c("train","test")) {
        infile <- paste("splits/",s,"/",j,"/",k,"/data",sep="")
        outfile <- paste("splits/",s,"/",j,"/",k,"/",f,sep="")
        if (s == "full" && substr(f,1,8) == "response" && k == "test") {
          # We can't compute the response on the actual test set, so just 
          # write a file with a header and no data.
          writeLines('response', outfile)
        } else {
          command <- paste("features/",f," --infile ",infile," --outfile ",outfile,sep="") 
          system(command)
        }
        cat(outfile,"\n")
      }
    }
   # TODO: Sanity check that all feature files within a split have the same length
   # sapply(list.files(paste("splits/",s,"/",j,sep="")),function(f) {
   #   as.numeric(read.table(pipe(paste('wc -l',f)))[1])
   #  })
   # }
  }
}


cat("done\n")
