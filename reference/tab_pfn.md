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
  training_set_limit = Inf,
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
  training_set_limit = Inf,
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
  training_set_limit = Inf,
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
  training_set_limit = Inf,
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

  An integer greater than 2L, or `Inf` (the default) to use every row.
  Anything smaller samples the training set down to that many rows,
  stratified by class for classification and by quartile for regression.
  Use it to speed up a fit, or to make one possible at all on a machine
  that cannot hold the whole training set.

- version:

  The model version, such as `"v2.5"` or `"v3.5"`. A bare number works
  too: `2.5`, `"2.5"`, and `"v2.5"` are equivalent. Call
  [`tabpfn_list_versions()`](https://tabpfn.tidymodels.org/reference/tabpfn_list_versions.md)
  for the versions your installed Python library offers. When `NULL`
  (the default), the Python library's current default version is used.
  When set, the model is initialized via `create_default_for_version()`
  with the corresponding `ModelVersion` enum value.

- control:

  A list of options produced by
  [`control_tab_pfn()`](https://tabpfn.tidymodels.org/reference/control_tab_pfn.md).

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
license and obtaining a token from PriorLabs. Every version from 2.5
onwards has its own license, and you must accept each one on its own.
Accepting the license for one version does not cover the others.

To set up access:

1.  Visit `https://ux.priorlabs.ai` and create an account.

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

#### Persistent Environment with [`install_tabpfn()`](https://tabpfn.tidymodels.org/reference/install_tabpfn.md)

Alternatively,
[`install_tabpfn()`](https://tabpfn.tidymodels.org/reference/install_tabpfn.md)
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
[`install_tabpfn()`](https://tabpfn.tidymodels.org/reference/install_tabpfn.md)
before tabpfn has initialized Python (i.e., before fitting a model); if
Python is already loaded, restart R first.

### Data

Each model version was pre-trained on data up to a certain size, and
those sizes have grown a great deal across versions. The *Data limits by
version* section below has the numbers.

These limits are enforced by the Python library, which raises when data
exceeds them. tabpfn does not check them itself, so the error you see
names the model actually loaded.

Predictors do not require preprocessing; missing values and factor
vectors are allowed.

### Model Selection

By default, TabPFN uses the Python library's current default model
version. There are two ways to override this.

#### Selecting a model version

Use the `version` argument to select a specific released model version:


      mod <- tab_pfn(predictors, outcome, version = "v2.5")

      # A bare number works too
      mod <- tab_pfn(predictors, outcome, version = 3.5)

New model versions are released from time to time, so rather than
listing them here, call
[`tabpfn_list_versions()`](https://tabpfn.tidymodels.org/reference/tabpfn_list_versions.md)
to see what your installed Python library offers:


      > tabpfn_list_versions()
      [1] "v2"    "v2.5"  "v2.6"  "v3"    "v3.5"  "v3.5-fast"

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

## Data limits by version

|               |            |            |            |         |
|---------------|------------|------------|------------|---------|
| Version       | Rows (GPU) | Rows (CPU) | Predictors | Classes |
| `"v3.5-fast"` | 1M         | 5K         | 20K        | 160     |
| `"v3.5"`      | 1M         | 5K         | 20K        | 160     |
| `"v3"`        | 1M         | 5K         | 2K         | 160     |
| `"v2.6"`      | 100K       | 1K         | 2K         | 10      |
| `"v2.5"`      | 50K        | 1K         | 2K         | 10      |
| `"v2"`        | 10K        | 1K         | 500        | 10      |

The CPU column is not advice. TabPFN refuses a CPU fit above that many
rows, whatever the version's own limit says, so `"v3.5"` stops at 5,000
rows on a machine without a GPU. Set `ignore_pretraining_limits = TRUE`
in
[`control_tab_pfn()`](https://tabpfn.tidymodels.org/reference/control_tab_pfn.md),
or the `TABPFN_ALLOW_CPU_LARGE_DATASET` environment variable, to lift
it. The fit then runs, slowly.

Every limit here is enforced by the Python library, which raises an
error naming the count and the limit. Use `training_set_limit` to fit on
a sample instead.

The row and predictor maxima trade off against each other, so you cannot
always reach both at once. The ceiling is not a promise either: for
`"v3.5"`, PriorLabs recommends up to 6,000 predictors even though the
model tops out at 20,000. See <https://docs.priorlabs.ai/models>.

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

Grinsztajn, Léo, et al. "Tabpfn-3: Technical report." *arXiv preprint*
arXiv:2605.13986 (2026).

Jäger, Benjamin, et al. "TabPFN-3.5: Technical Report." *arXiv preprint*
arXiv:2609.17895 (2026).

## See also

[`control_tab_pfn()`](https://tabpfn.tidymodels.org/reference/control_tab_pfn.md),
[`predict.tab_pfn()`](https://tabpfn.tidymodels.org/reference/predict.tab_pfn.md)

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
