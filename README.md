# pipeline

Authors: Chris DuBois and Drew Frank
Date: March 1, 2012

A lightweight framework for data mining.

## Installation

If your new project is called `competition`:

```bash
mkdir competition
cd competition
git clone git@github.com:doobwa/pipeline.git
source pipeline/startup
pipeline init
```

## Available commands
`pipeline init`
Initializes a directory with the needed directory structure.

`pipeline status`

`pipeline split kfold 5 [filename]`

Executes splits/kfold.r with K=5 to the specified file (e.g. rawdata/training.csv).  Any script in the splits folder should create a folder in data with subfolders for each split, and further subfolders for train and test portions.

`pipeline compute [feature]`

Executes `features/[name]`, which should compute one (or more) column files for every available split in the `splits/` directory.

`pipeline push [cluster]`

Executes the jobs in `queue` using GNU parallel.  (Currently only the `datalab` cluster is implemented.)

## Planned commands

`pipeline stage [method] [method.id] [dataset]`

This adds a series of commands to the queue.  One may specify a particular method to be used via method, or a particular `dataset` to apply methods to.  If a method is specified, one may further specify the arguments of choice by providing a `method.id` (the position of the desired arguments in the list of arguments as found in the config.json file). 

The training file is named `data/[split_name]/[split #]/train` and the test file  `data/[split_name]/[split #]/test`. (Both of these are constructed on the fly using a named pipe from the dataset's features as found in these split folders.)
By default, `method` and `dataset` are set to "all".  

*status*: This cannot be completed until we know how to send a particular set of features to a method.

## How it works

A feature is computed on a given set of data and represents one or more columns of data.  Features can be *dense* where each comma represents a given column, or *sparse*.

A dataset is a named colleciton of features.  When a method is executed for a particular dataset, the respective features are combined on the fly via a named pipe and the method's script is executed.

## API

### Method scripts and wrappers

Each script in the `methods/` folder should accept arguments specific to that method as well as:

- `--train`: filename for the training data to be used
- `--test`: filename for the test data
- `--predictions`: filename for saving predictions for the test data
- `--log`: filename for writing log data, if it exists

### Scripts that create features

Each script in the `features/` folder should accept:

- `--infile`: file used for computing the feature
- `--outfile`: location to save the data. 
  -- Features that are `dense` should save a csv file with a header row describing each column.
  -- Features that are `sparse` should be (roughly) in svm format, where each row is a space-sparated sequence of `[feature_name]:[feature_value]` pairs.


## Directory structure

`splits/`

Each subdirectory is a particular type of cross-validation split.  For example `splits/5fold` is a type of cross-validation split that will have two subdirectories, `train` and `test`, containing a file for each feature that can be used.
