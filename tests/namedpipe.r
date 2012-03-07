#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--infile", help=""),
  make_option("--outfile", help="")
  )
opts   <- parse_args(OptionParser(option_list=option_list))

out <- read.csv(opts$infile)
write(out,file=opts$outfile)