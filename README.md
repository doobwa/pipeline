# pipeline

Authors: Chris DuBois and Drew Frank
Date: March 1, 2012

A lightweight framework for data mining.

## Installation


## Available commands
`pipeline init`
Initializes a directory with the needed directory structure.

`pipeline status`

`pipeline split kfold 5 [filename]`

Executes splits/kfold.r with K=5 to the specified file (e.g. rawdata/training.csv).  Any script in the splits folder should create a folder in data with subfolders for each split, and further subfolders for train and test portions.

## Planned commands
`pipeline stage [method] [method.id] [dataset]`
This adds a series of commands to the queue.  One may specify a particular method to be used via method, or a particular `dataset` to apply methods to.  If a method is specified, one may further specify the arguments of choice by providing a `method.id` (the position of the desired arguments in the list of arguments as found in the config.json file).
By default, `method` and `dataset` are set to "all".  

*status*: This cannot be completed until we know how to send a particular set of features to a method.

`pipeline add dataset [dataset name]`
Add a dataset to the list of datasets to be evaluated.

`pipeline eval`

`pipeline features [name]`

Executes features/[name], which should compute one (or more) column files for every available split in the data/ directory.
