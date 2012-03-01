#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))

option_list <- list(
  make_option(c("-f", "--directory"), 
              help="Root directory for project.")
  )
parser <- OptionParser(usage = "%prog [options] file", option_list=option_list)
opts   <- parse_args(OptionParser(option_list=option_list))

dir.create(paste(opts$directory,"/data/",sep=""))
for (i in 0:5) dir.create(paste(opts$directory,"/data/",i,sep=""))

dir.create(paste(opts$directory,"/predictions/",sep=""))
dir.create(paste(opts$directory,"/logs/",sep=""))
for (i in 0:5) {
  dir.create(paste(opts$directory,"/predictions/",i,sep=""))
  dir.create(paste(opts$directory,"/predictions/",i,"/train",sep=""))
  dir.create(paste(opts$directory,"/predictions/",i,"/test",sep=""))
  dir.create(paste(opts$directory,"/logs/",i,sep=""))
  dir.create(paste(opts$directory,"/logs/",i,"/train",sep=""))
  dir.create(paste(opts$directory,"/logs/",i,"/test",sep=""))
}