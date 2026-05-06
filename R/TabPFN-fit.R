#' Fit a TabPFN model.
#'
#' `tab_pfn()` applies data to a pre-estimated deep learning model defined by
#' Hollmann _et al_ (2025). This model emulates Bayesian inference for
#' regression and classification models.
#'
#' @param x Depending on the context:
#'
#'   * A __data frame__ of predictors.
#'   * A __matrix__ of predictors.
#'   * A __recipe__ specifying a set of preprocessing steps
#'     created from [recipes::recipe()].
#'
#' @param y When `x` is a __data frame__ or __matrix__, `y` is the outcome
#' specified as:
#'
#'   * A __data frame__ with 1 numeric column.
#'   * A __matrix__ with 1 numeric column.
#'   * A numeric __vector__ for regression or a __factor__ for classification.
#'
#' @param data When a __recipe__ or __formula__ is used, `data` is specified as:
#'
#'   * A __data frame__ containing both the predictors and the outcome.
#'
#' @param formula A formula specifying the outcome terms on the left-hand side,
#' and the predictor terms on the right-hand side.
#'
#' @param num_estimators An integer for the ensemble size. Default is `8L`.
#'
#' @param softmax_temperature An adjustment factor that is a divisor in the
#' exponents of the softmax function (see Details below). Defaults to 0.9.
#'
#' @param balance_probabilities A logical to adjust the prior probabilities in
#' cases where there is a class imbalance. Default is `FALSE`. Classification
#' only.
#'
#' @param average_before_softmax A logical. For cases where
#' `num_estimators > 1`, should the average be done before using the softmax
#' function or after? Default is `FALSE`.
#'
#' @param training_set_limit An integer greater than 2L (and possibly `Inf`)
#' that can be used to keep the training data within the limits of the
#' data constraints imposed by the Python library.
#'
#' @param control A list of options produced by [control_tab_pfn()].
#'
#' @param ... Not currently used, but required for extensibility.
#'
#' @details
#'
#' ## Computing Requirements
#'
#' This model can be used with or without a graphics processing unit (GPU).
#' However, it is fairly limited when used with a CPU (and no GPU). There might
#' be additional data size limitation warnings with CPU computations, and,
#' understandably, the execution time is much longer. CPU computations can also
#' consume a significant amount of system memory, depending on the size of your
#' data.
#'
#' GPUs using CUDA (Compute Unified Device Architecture) are most effective.
#' Limited testing with others has shown that GPUs with Metal Performance
#' Shaders (MPS) instructions (e.g., Apple GPUs) have limited utility for these
#' specific computations and might be slower than the CPU for some data sets.
#'
#' ## License Requirements
#'
#' On November 6, 2025, PriorLabs released version 2.5 of the model, which
#' contained several improvements. One other change is that accessing the model
#' parameters required an API key. Without one, an error occurs:
#'
#' "This model is gated and requires you to accept its terms.  Please
#' follow these steps: 1. Visit [https://huggingface.co/Prior-Labs/tabpfn_2_5](https://huggingface.co/Prior-Labs/tabpfn_2_5)
#' in your browser and accept the terms of use. 2. Log in to your Hugging Face
#' account via the command line by running: hf auth login (Alternatively, you
#' can set the HF_TOKEN environment variable with a read token)."
#'
#' The license contains provisions for "Non-Commercial Use Only" usage if that
#' is relevant for you.
#'
#' To get an API key, use the `huggingface` link above, create an account, and
#' then get an API key. Once you have that, put it in your `.Renviron` file in
#' the form of:
#'
#' \preformatted{
#' HF_TOKEN=your_api_key_value
#' }
#'
#' The \pkg{usethis} function `edit_r_environ()` can be very helpful here.
#'
#' ## Python Installation
#'
#' You will need a working Python virtual environment with the correct packages
#' to use these modeling functions.
#'
#' There are at least two ways to proceed.
#'
#' ### Ephemeral `uv` Install
#'
#' The first approach, which we *strongly suggest*, is to simply load this
#' package and attempt to run a model. This will prompt \pkg{reticulate} to
#' create an ephemeral environment and automatically install the required
#' packages. That process would look like this:
#'
#' \preformatted{
#'   > library(tabpfn)
#'   >
#'   > predictors <- mtcars[, -1]
#'   > outcome <- mtcars[, 1]
#'   >
#'   > # XY interface
#'   > mod <- tab_pfn(predictors, outcome)
#'   Downloading uv...Done!
#'   Downloading cpython-3.12.12 (download) (15.9MiB)
#'    Downloading cpython-3.12.12 (download)
#'   Downloading setuptools (1.1MiB)
#'   Downloading scikit-learn (8.2MiB)
#'   Downloading numpy (4.9MiB)
#'
#'   <downloading and installing more packages>
#'
#'    Downloading llvmlite
#'    Downloading torch
#'   Installed 58 packages in 350ms
#'   > mod
#'   TabPFN Regression Model
#'
#'   Training set
#'   i 32 data points
#'   i 10 predictors
#' }
#'
#' The location of the environment can be found at
#' `tools::R_user_dir("reticulate", "cache")`.
#'
#' See the documentation for [reticulate::py_require()] to learn more about this
#' method.
#'
#' ### Manually created `venv` Virtual Environment
#'
#' Alternatively, you can use the functions in the \pkg{reticulate} package to
#' create a virtual environment and install the required Python packages there.
#' An example pattern is:
#'
#' \preformatted{
#'   library(reticulate)
#'
#'   venv_name <- "r-tabpfn"    # exact name can be different
#'   venv_seed_python <-
#'     virtualenv_starter(">=3.11,<3.14") %||% install_python()
#'
#'   virtualenv_create(
#'     envname = venv_name,
#'     python = venv_seed_python,
#'     packages = c("numpy", "tabpfn")
#'   )
#' }
#'
#' Once you have that virtual environment installed, you can declare it as your
#' preferred Python installation with `use_virtualenv()`. (You must do this
#' before reticulate has initialized Python, i.e., before attempting to use
#' \pkg{tabpfn}):
#'
#' \preformatted{
#'   reticulate::use_virtualenv("r-tabpfn")
#' }
#'
#' ## Data
#'
#' Be default, there are limits to the training data dimensions:
#'
#'   * Version 2.0: number of training set samples (10,000) and, the number of
#'   predictors (500). There is an unchangeable limit to the number of classes
#'   (10).
#'
#'   * Version 2.5: number of training set samples (50,000) and, the number of
#'   predictors (2,000). There is an unchangeable limit to the number of classes
#'   (10).
#'
#' Predictors do not require preprocessing; missing values and factor vectors
#' are allowed.
#'
#' ## Calculations
#'
#' For the `softmax_temperature` value, the softmax terms are:
#'
#' \preformatted{
#' exp(value / softmax_temperature)
#' }
#'
#' A value of `softmax_temperature = 1` results in a plain softmax value.
#'
#' @return
#'
#' A `tab_pfn` object with elements:
#'
#'   * `fit`: the python object containing the model.
#'   * `levels`: a character string of class levels (or NULL for regression)
#'   * `training`: a vector with the training set dimensions.
#'   * `logging`: any R or python messages produced by the computations.
#'   * `blueprint`: am object produced by [hardhat::mold()] used to process
#'      new data during prediction.
#'
#' @references
#'
#' Hollmann, Noah, Samuel Müller, Lennart Purucker, Arjun Krishnakumar, Max
#' Körfer, Shi Bin Hoo, Robin Tibor Schirrmeister, and Frank Hutter.
#' "Accurate predictions on small data with a tabular foundation model."
#'  _Nature_ 637, no. 8045 (2025): 319-326.
#'
#' Hollmann, Noah, Samuel Müller, Katharina Eggensperger, and Frank Hutter.
#' "Tabpfn: A transformer that solves small tabular classification problems in
#' a second." _arXiv preprint_ arXiv:2207.01848 (2022).
#'
#' Müller, Samuel, Noah Hollmann, Sebastian Pineda Arango, Josif Grabocka, and
#' Frank Hutter. "Transformers can do Bayesian inference." _arXiv preprint_
#' arXiv:2112.10510 (2021).
#'
#' @seealso [control_tab_pfn()], [predict.tab_pfn()]
#' @examples
#' predictors <- mtcars[, -1]
#' outcome <- mtcars[, 1]
#'
#' \dontrun{
#' if (is_tab_pfn_installed() & interactive()) {
#'  # XY interface
#'  mod <- tab_pfn(predictors, outcome)
#'
#'  # Formula interface
#'  mod2 <- tab_pfn(mpg ~ ., mtcars)
#'
#'  # Recipes interface
#'  if (rlang::is_installed("recipes")) {
#'   suppressPackageStartupMessages(library(recipes))
#'   rec <-
#'    recipe(mpg ~ ., mtcars) %>%
#'    step_log(disp)
#'
#'   mod3 <- tab_pfn(rec, mtcars)
#'   mod3
#'  }
#' }
#' }
#'
#' @export
tab_pfn <- function(x, ...) {
  UseMethod("tab_pfn")
}

#' @export
#' @rdname tab_pfn
tab_pfn.default <- function(x, ...) {
  cli::cli_abort("{.fn tab_pfn} is not defined for {obj_type_friendly(x)}.")
}

# XY method - data frame

#' @export
#' @rdname tab_pfn
tab_pfn.data.frame <- function(
  x,
  y,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  control = control_tab_pfn(),
  ...
) {
  options <- control
  options$n_estimators <- num_estimators
  options$softmax_temperature <- softmax_temperature
  options$balance_probabilities <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  processed <- hardhat::mold(x, y)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  tab_pfn_bridge(processed, options, ...)
}

# XY method - matrix

#' @export
#' @rdname tab_pfn
tab_pfn.matrix <- function(
  x,
  y,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  control = control_tab_pfn(),
  ...
) {
  options <- control
  options$n_estimators <- num_estimators
  options$softmax_temperature <- softmax_temperature
  options$balance_probabilities <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  processed <- hardhat::mold(x, y)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  tab_pfn_bridge(processed, options, ...)
}

# Formula method

#' @export
#' @rdname tab_pfn
tab_pfn.formula <- function(
  formula,
  data,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  control = control_tab_pfn(),
  ...
) {
  options <- control
  options$n_estimators <- num_estimators
  options$softmax_temperature <- softmax_temperature
  options$balance_probabilities <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  # No not convert factors to indicators:
  bp <- hardhat::default_formula_blueprint(
    intercept = FALSE,
    allow_novel_levels = FALSE,
    indicators = "none",
    composition = "tibble"
  )
  processed <- hardhat::mold(formula, data, blueprint = bp)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  tab_pfn_bridge(processed, options, ...)
}

# Recipe method

#' @export
#' @rdname tab_pfn
tab_pfn.recipe <- function(
  x,
  data,
  num_estimators = 8L,
  softmax_temperature = 0.9,
  balance_probabilities = FALSE,
  average_before_softmax = FALSE,
  training_set_limit = 10000,
  control = control_tab_pfn(),
  ...
) {
  options <- control
  options$n_estimators <- num_estimators
  options$softmax_temperature <- softmax_temperature
  options$balance_probabilities <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  processed <- hardhat::mold(x, data)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  tab_pfn_bridge(processed, options, ...)
}

# ------------------------------------------------------------------------------
# Bridge

tab_pfn_bridge <- function(processed, options, ...) {
  rlang::check_dots_empty()

  predictors <- processed$predictors
  outcome <- processed$outcomes[[1]]

  check_data_constraints(predictors, outcome, options)

  res <- tab_pfn_impl(predictors, outcome, options)

  new_tab_pfn(
    fit = res$fit,
    levels = res$lvls,
    training = res$train,
    logging = res$logging,
    blueprint = processed$blueprint
  )
}

# ------------------------------------------------------------------------------
# Implementation

tab_pfn_impl <- function(x, y, opts) {
  tabpfn <- .pkg_env$tab_pfn
  cls_wrapper <- function(...) {
    tabpfn$TabPFNClassifier(...)
  }
  reg_wrapper <- function(...) {
    tabpfn$TabPFNRegressor(...)
  }

  if (is.factor(y)) {
    cls_cl <- rlang::call2("cls_wrapper", !!!opts)
    mod_obj <- rlang::eval_bare(cls_cl)
  } else if (is.numeric(y)) {
    opts <- opts[names(opts) != "balance_probabilities"]
    cls_cl <- rlang::call2("reg_wrapper", !!!opts)
    mod_obj <- rlang::eval_bare(cls_cl)
  }

  py_msg <- reticulate::py_capture_output(
    model_fit <- try(mod_obj$fit(x, y), silent = TRUE)
  )

  if (inherits(model_fit, "try-error")) {
    msgs <- as.character(model_fit)
    cli::cli_abort("Model failed: {msgs}")
  } else {
    msgs <- character(0)
  }

  # check for failures
  res <- list(
    fit = model_fit,
    lvls = levels(y),
    train = dim(x),
    logging = c(r = msgs, py = py_msg)
  )
  class(res) <- c("tab_pfn")
  res
}

#' @export
print.tab_pfn <- function(x, ...) {
  type <- ifelse(is.null(x$levels), "Regression", "Classification")
  cli::cli_inform("TabPFN {type} Model")
  cat("\n")
  cli::cli_inform("Training set\n\n")
  cli::cli_inform(c(i = "{x$training[1]} data point{?s}"))
  cli::cli_inform(c(i = "{x$training[2]} predictor{?s}"))

  if (!is.null(x$levels)) {
    cli::cli_inform(c(i = "class levels: {.val {x$levels}}"))
  }

  invisible(x)
}

check_fit_args <- function(opts, call = rlang::caller_env()) {
  check_number_whole(
    # These arg names are deliberately different
    opts$n_estimators,
    arg = "num_estimators",
    min = 1,
    call = call
  )
  opts$n_estimators <- as.integer(opts$n_estimators)

  check_number_decimal(
    opts$softmax_temperature,
    arg = "softmax_temperature",
    min = .Machine$double.eps,
    call = call
  )

  check_logical(
    opts$balance_probabilities,
    arg = "balance_probabilities",
    call = call
  )

  check_logical(
    opts$average_before_softmax,
    arg = "average_before_softmax",
    call = call
  )

  # ------------------------------------------------------------------------------
  # There have been some argument name differences in the python package versions

  arg_names <- names(opts)
  py_lib <- try(reticulate::import("tabpfn"), silent = TRUE)
  if (inherits(py_lib, "try-error")) {
    cli::cli_alert_danger(
      "The {.code tabpfn} Python library could not be imported."
    )
    url <- "https://rstudio.github.io/reticulate/articles/versions.html#order-of-discovery"
    cli::cli_inform("See {.url {url}} for more information.")
    cli::cli_bullets(
      c(
        i = "Environmental variables:",
        i = "{.code RETICULATE_PYTHON}: {show_env_var('RETICULATE_PYTHON')}",
        i = "{.code RETICULATE_PYTHON_ENV}: {show_env_var('RETICULATE_PYTHON_ENV')}",
        i = "{.code RETICULATE_USE_MANAGED_VENV}: {show_env_var('RETICULATE_USE_MANAGED_VENV')}",
        i = "{.code VIRTUAL_ENV}: {show_env_var('VIRTUAL_ENV')}"
      )
    )
    cli::cli_abort(
      "The {.code tabpfn} Python library could not be imported.",
      call = NULL
    )
  }

  py_arg_names <- names(formals(py_lib$TabPFNClassifier))
  if (any(py_arg_names == "n_jobs")) {
    names(opts) <- gsub("^n_preprocessing_jobs$", "n_jobs", names(opts))
  }

  # ------------------------------------------------------------------------------

  opts
}

show_env_var <- function(x) {
  val <- Sys.getenv(x)
  if (identical(val, "")) {
    val <- "<not set>"
  }
  val
}
