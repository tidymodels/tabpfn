# Fit a TabPFN model.

`tab_pfn()` applies data to a pre-estimated deep learning model defined
by Hollmann *et al* (2025). This model emulates Bayesian inference for
regression and classification models.

## Usage

``` r
tab_pfn(x, ...)

# Default S3 method
tab_pfn(x, ...)

# S3 method for class 'data.frame'
tab_pfn(
  x,
  y,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  version = NULL,
  control = control_tab_pfn(),
  ...
)

# S3 method for class 'matrix'
tab_pfn(
  x,
  y,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  version = NULL,
  control = control_tab_pfn(),
  ...
)

# S3 method for class 'formula'
tab_pfn(
  formula,
  data,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  version = NULL,
  control = control_tab_pfn(),
  ...
)

# S3 method for class 'recipe'
tab_pfn(
  x,
  data,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  version = NULL,
  control = control_tab_pfn(),
  ...
)
```

## Arguments

- x:

  Depending on the context:

  - A **data frame** of predictors.

  - A **matrix** of predictors.

  - A **recipe** specifying a set of preprocessing steps created from
    [`recipes::recipe()`](https://recipes.tidymodels.org/reference/recipe.html).

- ...:

  Not currently used, but required for extensibility.

- y:

  When `x` is a **data frame** or **matrix**, `y` is the outcome
  specified as:

  - A **data frame** with 1 numeric column.

  - A **matrix** with 1 numeric column.

  - A numeric **vector** for regression or a **factor** for
    classification.

- num_estimators:

  An integer for the ensemble size. Default is `8L`.

- softmax_temperature:

  An adjustment factor that is a divisor in the exponents of the softmax
  function (see Details below). Defaults to 0.9.

- balance_probabilities:

  A logical to adjust the prior probabilities in cases where there is a
  class imbalance. Default is `FALSE`. Classification only.

- average_before_softmax:

  A logical. For cases where `num_estimators > 1`, should the average be
  done before using the softmax function or after? Default is `FALSE`.

- training_set_limit:

  An integer greater than 2L (and possibly `Inf`) that can be used to
  keep the training data within the limits of the data constraints
  imposed by the Python library.

- version:

  A character string for the model version (e.g., `"v2"`, `"v2.5"`).
  When `NULL` (the default), the Python library's current default
  version is used. When set, the model is initialized via
  `create_default_for_version()` with the corresponding `ModelVersion`
  enum value.

- control:

  A list of options produced by
  [`control_tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/control_tab_pfn.md).

- formula:

  A formula specifying the outcome terms on the left-hand side, and the
  predictor terms on the right-hand side.

- data:

  When a **recipe** or **formula** is used, `data` is specified as:

  - A **data frame** containing both the predictors and the outcome.

## Value

A `tab_pfn` object with elements:

- `fit`: the python object containing the model.

- `levels`: a character string of class levels (or NULL for regression)

- `training`: a vector with the training set dimensions.

- `version`: the underlying TabPFN model version (or `"unknown"` if it
  cannot be determined).

- `device`: the device(s) the model was fitted on, e.g. `"cpu"`,
  `"mps"`, or `"cuda:0"` (or `"unknown"` if it cannot be determined).

- `logging`: any R or python messages produced by the computations.

- `blueprint`: am object produced by
  [`hardhat::mold()`](https://hardhat.tidymodels.org/reference/mold.html)
  used to process new data during prediction.

## Details

### Computing Requirements

This model can be used with or without a graphics processing unit (GPU).
However, it is fairly limited when used with a CPU (and no GPU). There
might be additional data size limitation warnings with CPU computations,
and, understandably, the execution time is much longer. CPU computations
can also consume a significant amount of system memory, depending on the
size of your data.

GPUs using CUDA (Compute Unified Device Architecture) are most
effective. Limited testing with others has shown that GPUs with Metal
Performance Shaders (MPS) instructions (e.g., Apple GPUs) have limited
utility for these specific computations and might be slower than the CPU
for some data sets.

### License Requirements

Starting with version 2.5, using TabPFN requires accepting the model
license and obtaining a token from PriorLabs. Each model version (v2.5,
v2.6, etc.) has its own license that must be accepted individually.

To set up access:

1.  Visit <https://ux.priorlabs.ai> and create an account.

2.  Go to the **License** tab and accept the license for each model
    version you intend to use.

3.  Obtain your token from your account page.

4.  Set the `TABPFN_TOKEN` environment variable. The easiest way is to
    add it to your `.Renviron` file:


    TABPFN_TOKEN=your_token_value

The usethis function `edit_r_environ()` can be very helpful here.

Users who already have `TABPFN_TOKEN` set can use TabPFN v2 without any
additional steps.

### Python Installation

You will need a working Python virtual environment with the correct
packages to use these modeling functions.

There are at least two ways to proceed.

#### Ephemeral `uv` Install

The first approach, which we *strongly suggest*, is to simply load this
package and attempt to run a model. This will prompt reticulate to
create an ephemeral environment and automatically install the required
packages. That process would look like this:


      > library(tabpfn)
      >
      > predictors <- mtcars[, -1]
      > outcome <- mtcars[, 1]
      >
      > # XY interface
      > mod <- tab_pfn(predictors, outcome)
      Downloading uv...Done!
      Downloading cpython-3.12.12 (download) (15.9MiB)
       Downloading cpython-3.12.12 (download)
      Downloading setuptools (1.1MiB)
      Downloading scikit-learn (8.2MiB)
      Downloading numpy (4.9MiB)

      <downloading and installing more packages>

       Downloading llvmlite
       Downloading torch
      Installed 58 packages in 350ms
      > mod
      TabPFN Regression Model

      Training set
      i 32 data points
      i 10 predictors

The location of the environment can be found at
`tools::R_user_dir("reticulate", "cache")`.

See the documentation for
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html)
to learn more about this method.

#### Persistent Environment with [`install_tabpfn()`](https://tabpfn.tidymodels.org/dev/reference/install_tabpfn.md)

Alternatively,
[`install_tabpfn()`](https://tabpfn.tidymodels.org/dev/reference/install_tabpfn.md)
creates a persistent virtual environment named `"r-tabpfn"` and installs
the Python `tabpfn` library into it:


      library(tabpfn)

      # Install the latest release
      install_tabpfn()

      # Or pin a specific version for reproducibility
      install_tabpfn(version = "2.0.9")

You do not need to call `use_virtualenv()` afterwards: because this
package imports the Python module `"tabpfn"`, reticulate automatically
discovers and prefers the `"r-tabpfn"` environment over the ephemeral
one. Run
[`install_tabpfn()`](https://tabpfn.tidymodels.org/dev/reference/install_tabpfn.md)
before tabpfn has initialized Python (i.e., before fitting a model); if
Python is already loaded, restart R first.

### Data

Be default, there are limits to the training data dimensions:

- Version 2.0: number of training set samples (10,000) and, the number
  of predictors (500). There is an unchangeable limit to the number of
  classes (10).

- Version 2.5: number of training set samples (50,000) and, the number
  of predictors (2,000). There is an unchangeable limit to the number of
  classes (10).

Predictors do not require preprocessing; missing values and factor
vectors are allowed.

### Model Selection

By default, TabPFN uses the Python library's current default model
version. There are two ways to override this.

#### Selecting a model version

Use the `version` argument to select a specific released model version.
For example:


      # Use version 2.0
      mod <- tab_pfn(predictors, outcome, version = "v2")

      # Use version 2.5
      mod <- tab_pfn(predictors, outcome, version = "v2.5")

#### Pointing to a local model file

If you have a model file on disk (e.g., downloaded for offline use),
pass its path via `control_tab_pfn(model_path = ...)`:


      ctrl <- control_tab_pfn(model_path = "/path/to/model_file.ckpt")
      mod  <- tab_pfn(predictors, outcome, control = ctrl)

Note that `version` and `model_path` are mutually exclusive: if
`version` is set, it overwrites any `model_path` supplied through
`control`.

### Calculations

For the `softmax_temperature` value, the softmax terms are:


    exp(value / softmax_temperature)

A value of `softmax_temperature = 1` results in a plain softmax value.

## References

Hollmann, Noah, Samuel Müller, Lennart Purucker, Arjun Krishnakumar, Max
Körfer, Shi Bin Hoo, Robin Tibor Schirrmeister, and Frank Hutter.
"Accurate predictions on small data with a tabular foundation model."
*Nature* 637, no. 8045 (2025): 319-326.

Hollmann, Noah, Samuel Müller, Katharina Eggensperger, and Frank Hutter.
"Tabpfn: A transformer that solves small tabular classification problems
in a second." *arXiv preprint* arXiv:2207.01848 (2022).

Müller, Samuel, Noah Hollmann, Sebastian Pineda Arango, Josif Grabocka,
and Frank Hutter. "Transformers can do Bayesian inference." *arXiv
preprint* arXiv:2112.10510 (2021).

## See also

[`control_tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/control_tab_pfn.md),
[`predict.tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/predict.tab_pfn.md)

## Examples

``` r
predictors <- mtcars[, -1]
outcome <- mtcars[, 1]

if (FALSE) { # \dontrun{
if (is_tab_pfn_installed() & interactive()) {
 # XY interface
 mod <- tab_pfn(predictors, outcome)

 # Formula interface
 mod2 <- tab_pfn(mpg ~ ., mtcars)

 # Recipes interface
 if (rlang::is_installed("recipes")) {
  suppressPackageStartupMessages(library(recipes))
  rec <-
   recipe(mpg ~ ., mtcars) %>%
   step_log(disp)

  mod3 <- tab_pfn(rec, mtcars)
  mod3
 }
}
} # }
```
