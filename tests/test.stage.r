#!/usr/bin/env Rscript

# Continue setup.
system('pipeline init')
system('pipeline split kfold data/train.csv 2')

# Stage some commands to the queue.
system('pipeline stage glm basic')

# Compare first line of queue to expected output.
line <- readLines('queue', 1)[[1]]
test.cmds <- strsplit(line, '; ')[[1]]
good.cmds <- readLines('../data/test.stage.txt')
for (i in 1:length(good.cmds)) {
  stopifnot(test.cmds[[i]] == good.cmds[[i]])
}
