#!/usr/bin/env Rscript
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("rjson"))

option_list <- list(
  make_option("--id", help=""),
  make_option("--train", help=""),
  make_option("--test", help=""),
  make_option("--predictions", help=""),
  make_option("--log", help="")
)
opts   <- parse_args(OptionParser(option_list=option_list))

config <- fromJSON(,"config.json")

args <- config$method[['glm']]$args[[as.numeric(opts$id) + 1]]  # id uses 0-based

desc <- paste("glm",opts$id,sep="_")

train <- read.csv(opts$train)
test  <- read.csv(opts$test)
fit <- glm(response ~ .,family=args$family,data=train)
yhat <- predict(fit,type="response",newdata=test)
write(paste(yhat,collapse="\n"),file=opts$predictions)
