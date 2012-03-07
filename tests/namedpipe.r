#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option("--infile", help="")
  )
opts   <- parse_args(OptionParser(option_list=option_list))

print(read.csv(fifo(opts$infile)))