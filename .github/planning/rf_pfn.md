# `rf_pfn()` Implementation Plan

## Overview

Add an `rf_pfn()` function that wraps the RF-PFN extension from the `tabpfn_extensions` Python package. RF-PFN combines scikit-learn tree structures (Random Forest or Decision Tree) with TabPFN models at each node/leaf for improved performance on tabular data.

The API mirrors `tab_pfn()` — S3 dispatch with hardhat integration — with a `tree_type` argument to select the tree variant. The inner TabPFN model is created automatically so the user never touches the `tabpfn` Python parameter directly. Internally there is a clean two-list separation: `options` (passed to the inner `TabPFNClassifier`/`TabPFNRegressor`) and `rf_opts` (passed to the RF/DT wrapper class).

---

## Python Background

RF-PFN lives in the `tabpfn_extensions` Python package (extra: `rf_pfn`):

```python
from tabpfn_extensions.rf_pfn import (
    RandomForestTabPFNClassifier, RandomForestTabPFNRegressor,
    DecisionTreeTabPFNClassifier,  DecisionTreeTabPFNRegressor
)
```

`tabpfn-extensions[rf_pfn]` adds no new pip dependencies beyond the core package (scikit-learn is already a core dep), so it is safe to always require. It is registered via `reticulate::py_require()` in `zzz.R` with no `delay_load` — the module is imported inline inside `rf_pfn_impl()` at call time.

---

## Parameters

**`rf_opts` — passed to the RF/DT wrapper class:**

| R argument           | Python name          | RF default (cls / reg) | DT default | DT support |
|----------------------|----------------------|------------------------|------------|------------|
| `tree_type`          | —                    | `"random_forest"`      | —          | ✅ |
| `max_depth`          | `max_depth`          | `5L`                   | `NULL`     | ✅ |
| `min_samples_split`  | `min_samples_split`  | `1000L` / `300L`       | `1000L`    | ✅ |
| `min_samples_leaf`   | `min_samples_leaf`   | `5L`                   | `1L`       | ✅ |
| `max_features`       | `max_features`       | `"sqrt"`               | `NULL`     | ✅ |
| `fit_nodes`          | `fit_nodes`          | `TRUE`                 | `TRUE`     | ✅ |
| `dt_average_logits`  | `dt_average_logits`  | `TRUE`                 | `TRUE`     | ✅ |
| `bootstrap`          | `bootstrap`          | `NULL` → Python default| —          | ❌ RF only |
| `rf_average_logits`  | `rf_average_logits`  | `NULL` → Python default| —          | ❌ RF only |
| `max_predict_time`   | `max_predict_time`   | `NULL` → Python default| —          | ❌ RF only |

**`options` — passed to the inner `TabPFNClassifier`/`TabPFNRegressor`:**

Built in each S3 method by starting with `control` and appending the same TabPFN model-level params used in `tab_pfn()`, then validated through the existing `check_fit_args()`:

| R argument               | Python name              | Default     |
|--------------------------|--------------------------|-------------|
| `num_estimators`         | `n_estimators`           | `8L`        |
| `softmax_temperature`    | `softmax_temperature`    | `0.9`       |
| `balance_probabilities`  | `balance_probabilities`  | `FALSE`     |
| `average_before_softmax` | `average_before_softmax` | `FALSE`     |
| `control`                | *(several fields)*       | `control_tab_pfn()` |
| `training_set_limit`     | —                        | `10000`     |

**RF-only params strategy:** `bootstrap`, `rf_average_logits`, and `max_predict_time` default to `NULL`. If the user passes a non-`NULL` value while `tree_type = "decision_tree"`, `check_rf_pfn_args()` aborts with a clear "not supported for decision trees" message. When `NULL`, they are simply omitted from the Python call, letting Python use its own defaults.

R-side defaults match the RF classifier Python defaults. DT Python defaults differ (`max_depth = NULL`, `min_samples_leaf = 1L`, `max_features = NULL`); this is noted in the documentation.

---

## Phase I — Implementation

### `R/RFPFN-fit.R`

#### S3 generic + methods

`rf_pfn()` dispatches on the class of `x`, following the exact same pattern as `tab_pfn()`:

- `rf_pfn.default()` — friendly error via `cli::cli_abort()`
- `rf_pfn.data.frame()`, `rf_pfn.matrix()` — XY interface
- `rf_pfn.formula()` — uses `hardhat::default_formula_blueprint(indicators = "none")`
- `rf_pfn.recipe()` — uses `hardhat::mold(x, data)`

All four S3 methods share the same parameter list. Each one:
1. Calls `rlang::arg_match(tree_type)` to validate early
2. Builds `options` the same way `tab_pfn()` methods do: start with `control`, then append the TabPFN model-level params (`num_estimators`, `softmax_temperature`, `balance_probabilities`, `average_before_softmax`) as named elements, then run through `check_fit_args()` (reusing the existing function from `TabPFN-fit.R`) which validates types and handles the `n_preprocessing_jobs` → `n_jobs` rename
3. Assembles `rf_opts` as a named list of the RF/DT-specific parameters
4. Calls `check_rf_pfn_args(tree_type, rf_opts)` to validate and coerce types
5. Calls `hardhat::mold()` to process predictors/outcome
6. Optionally calls `sample_indicies()` to respect `training_set_limit`
7. Hands off to `rf_pfn_bridge()`

#### `rf_pfn_bridge()`

Mirrors `tab_pfn_bridge()`. Calls `check_data_constraints()` (reusing the existing function from `misc.R`), then `rf_pfn_impl()`, then wraps the result in `new_rf_pfn()`. Receives both `options` (inner TabPFN config) and `rf_opts` (tree config) as separate arguments.

```r
rf_pfn_bridge <- function(processed, tree_type, options, rf_opts, ...) {
  rlang::check_dots_empty()
  predictors <- processed$predictors
  outcome    <- processed$outcomes[[1]]
  check_data_constraints(predictors, outcome, options)
  res <- rf_pfn_impl(predictors, outcome, tree_type, options, rf_opts)
  new_rf_pfn(
    fit = res$fit, levels = res$lvls, training = res$train,
    logging = res$logging, tree_type = tree_type, blueprint = processed$blueprint
  )
}
```

#### `rf_pfn_impl()` — detailed sketch

```r
rf_pfn_impl <- function(x, y, tree_type, options, rf_opts) {
  tabpfn_lib <- reticulate::import("tabpfn")
  ext_lib    <- reticulate::import("tabpfn_extensions")

  # 1. Instantiate the inner TabPFN model. `options` already contains the full
  #    validated TabPFN config built by the S3 methods. For regression, drop
  #    balance_probabilities as tab_pfn() does, then use the regressor.
  if (is.factor(y)) {
    inner_wrapper <- function(...) tabpfn_lib$TabPFNClassifier(...)
  } else {
    options <- options[names(options) != "balance_probabilities"]
    inner_wrapper <- function(...) tabpfn_lib$TabPFNRegressor(...)
  }
  inner_model <- rlang::eval_bare(rlang::call2("inner_wrapper", !!!options))

  # 2. Add tabpfn= to rf_opts; drop any NULL-valued RF-only params so Python
  #    uses its own defaults rather than receiving explicit NULL / None.
  rf_opts$tabpfn <- inner_model
  rf_opts <- purrr::discard(rf_opts, is.null)

  # 3. Select the correct RF-PFN Python class based on tree_type + outcome type.
  if (tree_type == "random_forest") {
    tree_prefix <- "RandomForest"
  } else {
    tree_prefix <- "DecisionTree"
  }
  if (is.factor(y)) {
    outcome_suffix <- "Classifier"
  } else {
    outcome_suffix <- "Regressor"
  }
  py_class_name <- paste0(tree_prefix, "TabPFN", outcome_suffix)
  rf_wrapper     <- function(...) ext_lib$rf_pfn[[py_class_name]](...)

  # 4. Instantiate the RF/DT model and fit it.
  mod_obj <- rlang::eval_bare(rlang::call2(rf_wrapper, !!!rf_opts))

  py_msg <- reticulate::py_capture_output(
    model_fit <- try(mod_obj$fit(x, y), silent = TRUE)
  )

  if (inherits(model_fit, "try-error")) {
    cli::cli_abort("Model failed: {as.character(model_fit)}")
  }

  list(
    fit     = model_fit,   # the fitted Python object (fit() returns self)
    lvls    = levels(y),   # NULL for regression
    train   = dim(x),
    logging = c(r = character(0), py = py_msg)
  )
}
```

#### `check_rf_pfn_args()`

Validates all parameters and returns the cleaned list:

- Aborts if any RF-only param is non-`NULL` when `tree_type = "decision_tree"`
- Uses `check_number_whole()`, `check_logical()`, `check_number_decimal()` from the standalone types file
- `max_features` accepts string, numeric, or `NULL`; anything else aborts
- Coerces `max_depth`, `min_samples_split`, `min_samples_leaf` to `integer`

#### `print.rf_pfn()`

Same structure as `print.tab_pfn()`. Displays tree variant and model type:

```
RF-PFN Random Forest Regression Model

Training set

ℹ 32 data points
ℹ 10 predictors
```

---

### `R/RFPFN-constructor.R`

`new_rf_pfn()` wraps `hardhat::new_model()` with class `"rf_pfn"`. Stores `tree_type` as an additional field (needed by `print.rf_pfn()`). No strict Python class name check — unlike `new_tab_pfn()`, the exact reticulate class names for the four RF-PFN classes are not yet confirmed and would need Python at coding time to verify.

---

### `R/RFPFN-predict.R`

`predict.rf_pfn()` forges new data through the stored blueprint, then branches on `object$levels` (NULL = regression) rather than dispatching on the Python object's class name. This avoids needing to know the exact reticulate class string at coding time.

```r
predict.rf_pfn <- function(object, new_data, ...) {
  rlang::check_dots_empty()
  forged <- hardhat::forge(new_data, object$blueprint)$predictors

  if (is.null(object$levels)) {
    # Regression
    res <- object$fit$predict(forged)
    tibble::tibble(.pred = as.vector(res))
  } else {
    # Classification
    res <- object$fit$predict_proba(forged)
    colnames(res) <- paste0(".pred_", object$fit$classes_)
    cls_ind <- apply(res, 1, which.max)
    res <- tibble::as_tibble(res)
    res$.pred_class <- factor(object$fit$classes_[cls_ind], levels = object$levels)
    res
  }
}
```

Both branches wrap the Python call in `reticulate::py_capture_output()` + `try()` and abort with a clear message on failure, matching the pattern in `TabPFN-predict.R`.

`augment.rf_pfn()` calls `predict()` then `cbind()`s with `new_data`, same as `augment.tab_pfn()`.

---

### `R/zzz.R` change

Add `reticulate::py_require("tabpfn-extensions[rf_pfn]")` immediately after the existing `py_require("tabpfn")`. No `delay_load` — `tabpfn_extensions` is imported inline inside `rf_pfn_impl()` at call time, not at package load.

---

## Phase II — Testing

New test file: `tests/testthat/test-RFPFN.R`

Follow the conventions in the existing test suite:

- `skip_if(!is_tab_pfn_installed())` and `skip_on_cran()` at the top of each test
- Helper fixtures at top of file (or in `helper.R`): a small numeric outcome vector and a factor outcome vector
- Cover:
  - XY, formula, and recipe interfaces for both regression and classification
  - `tree_type = "random_forest"` and `tree_type = "decision_tree"`
  - `predict()` returns correct column names and row count
  - `augment()` returns correct structure
  - `print()` snapshot test
  - RF-only params error when `tree_type = "decision_tree"` (one test per param: `bootstrap`, `rf_average_logits`, `max_predict_time`)
  - `training_set_limit` subsampling still produces a fittable model
  - Invalid argument types (e.g. `max_depth = "foo"`) produce informative errors

---

## Phase III — Documentation

- Roxygen `@param` blocks for all arguments in `R/RFPFN-fit.R`, following the same style as `tab_pfn()`
- `@details` section covering:
  - How the inner TabPFN model is configured (pointer to `control_tab_pfn()`)
  - Which parameters differ between RF and DT Python defaults
  - The RF-only restriction and what error to expect
- `@return` describing the `rf_pfn` object fields (`fit`, `levels`, `training`, `logging`, `tree_type`, `blueprint`)
- `@examples` block with `\dontrun{}` guard showing XY, formula, and DT usage
- `@seealso` linking to `control_tab_pfn()` and `tab_pfn()`
- `@references` citing the RF-PFN extension documentation at `https://docs.priorlabs.ai/extensions/rf-pfn`
- `NEWS.md` entry for the new function
