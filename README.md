# pipeline

A lightweight framework for predictive modeling.

Authors: Chris DuBois and Drew Frank

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

(soon) `pipeline split full [filename]`

`pipeline split kfold [filename] [K]`

Executes splits/kfold.r with K=5 to the specified file (e.g. rawdata/training.csv).  Any script in the splits folder should create a folder in data with subfolders for each split, and further subfolders for train and test portions.

`pipeline compute [feature]`

Executes `features/[feature]`, which should compute one (or more) column files for every available split in the `splits/` directory.

`pipeline push [cluster]`

Executes the jobs in `queue` using GNU parallel.  (Currently only the `datalab` cluster is implemented.)

`pipeline stage [method] [dataset]`
`pipeline stage [method]:[method.id] [dataset]`

This adds a series of commands to the queue to fit and evaluate a series of methods on a series of datasets.  One may specify a particular `method` to be used via method, or a particular `dataset` to apply methods to.  

If a method is specified, one may further specify the arguments of choice by providing a `method.id` (the position of the desired arguments in the list of arguments as found in the config.json file). 

The training file is named `data/[split_name]/[split #]/train` and the test file  `data/[split_name]/[split #]/test`. (Both of these are constructed on the fly using a named pipe from the dataset's features as found in these split folders.)

## How it works

A feature is computed on a given set of data and represents one or more columns of data.  Features can be *dense* where each comma represents a given column, or *sparse*.

A dataset is a named colleciton of features.  When a method is executed for a particular dataset, the respective features are combined on the fly via a named pipe and the method's script is executed.

## Example of `config.json`

The following is an example of a simple `config.json` file.  It has a named data set called `basic` that has two features and a response, and is evaluated based on RMSE using two types of cross validation, 5fold and full.  (Full refers to using the entire training set and predicting on the validation set.  Unlike other splits, it requires two files: train and validation.)

The `feature` element describes whether each of the available features is either 'dense' or 'sparse'.  Each feature corresponds to a file with identical name in the `features/` folder.  All features in this list will be computed via the command `pipeline compute`.

The `method` element contains an array of methods to be considered.  The command `pipeline stage all [dataset]` uses all methods in this array.  Each method has a list of possible arguments.  Each unique method call is identified by its placement in this argument list, e.g. in the example below `glm 0` refers to the glm model where `family="gaussian"`.  The `data` attribute describes the types of `dataset` that this method can be applied to (though at this time no sanity checking is done).

The "basic" dataset below specifies the optional "pred_transform" file. This will cause the predictions written by the method to be stored in a file with a ".raw" suffix, which will then be processed by the transform script (scripts/unscale in this case) and written to the usual location.

```json
{
    "dataset": {
        "basic": {
          "features": [
              "response",
              "feature1",
              "feature2"
          ], 
          "splits": ["5fold","full"],
          "metric": "rmse",
          "pred_transform": "unscale",
          "eval_aux": "id_features"
        }
    }, 
    "feature": {
      "response": "dense",
      "feature1": "dense", 
      "feature2": "sparse"
    }, 
    "method": {
      "glm": {
        "args":[{"family":"gaussian"}],
        "data":"basic"
      }
    },
    "ensemble": {
      "average":{
        "combos" :[
          ["random_forest_0_basic4","glm_0_basic4"] 
        ],
        "splits": ["5fold","full"],
        "metric": ["rmse","essays_long"],
        "eval_aux": "set_domain",
        "pred_transform": "round_truncate"
      }
    }
}
```

## API

### Method scripts and wrappers

Each script in the `methods/` folder should accept arguments specific to that method as well as:

- `--id`: identifier for the set of arguments to use
- `--train`: filename for the training data to be used
- `--test`: filename for the test data
- `--predictionsTrain`: filename for saving predictions for the training data
- `--predictionsTest`: filename for saving predictions for the test data
- `--log`: filename for writing log data, if it exists

Any other arguments that are needed should be pulled from `config.json`.

The predictions file created by this script should begin with "predictions" and have a single prediction for each row.  This file should have the same number of lines as the provided test file.

### Scripts that create features

Each script in the `features/` folder should accept:

- `--infile`: file used for computing the feature
- `--outfile`: location to save the data. 
  -- Features that are `dense` should save a csv file with a header row describing each column.n
  -- Features that are `sparse` should be (roughly) in svm format, where each row is a space-sparated sequence of `[feature_name]:[feature_value]` pairs.

### Script for creating submissions

The `submit` file should be a script accepting:

- `--infile`: file containing predictions
- `--outfile`: desired location for submission-ready text file

By convention, the outfile should be in the `submissions/` directory.

### Script for transforming predictions

In some contexts it is helpful to do post-processing on a set of predictions.  The name of this script should be added to a `pred_transform` field of a dataset in `config.json`.  

- `--infile`: file containing predictions
- `--aux`: file pointing to additional features needed for performing the transform
- `--outfile`: desired location for new predictions

By default, the `--aux` parameter is populated using the `eval_aux` in `config.json`, if available.

## Directory structure

`splits/`

Each subdirectory is a particular type of cross-validation split.  For example `splits/5fold` is a type of cross-validation split that will have two subdirectories, `train` and `test`, containing a file for each feature that can be used.

`predictions/`

This directory mimics the structure of `splits/`, but the files are predictions made on the given split.  Files are named according to the method, the method id, and the `dataset` used (as described in the config file).

## Example

A typical pipeline session:

```bash
# Create cross-validation splits with 5 folds
pipeline split kfold rawdata/training.csv 5

# Compute all the features for all the splits
pipeline compute all

# Stage all the commands needed to run the gbm method (with argument sets defined 
# in config.json) on the dataset named basic_features.
pipeline stage gbm basic_features

# Push all the commands to be processed in parallel on datalab (eventually Amazon web services too)
pipeline push datalab

# Check the status of staged commands in the queue, etc.
pipeline status

# Look at the progress over time for each method, feature, etc.  Evaluation 
# metric defined on config.json.
pipeline dashboard

```

## Contributing

Adding new method wrappers (e.g. liblinear, etc) is always welcome.

The preferred way of updating your local repo before pushing to github is shown below.

```bash
git fetch origin
git rebase -p origin/master
``` 

