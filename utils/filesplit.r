#!/usr/bin/env Rscript

suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--infile", help=""),
  make_option("--outfile", help=""),
  make_option("--indices", help="")
  )
opts   <- parse_args(OptionParser(option_list=option_list))

x <- readLines(opts$infile)
ix <- scan(opts$indices)  # 0-based
write(paste(x[ix+1],collapse="\n"),file=opts$outfile)