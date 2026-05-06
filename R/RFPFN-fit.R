#' @export
rf_pfn <- function(x, ...) {
  UseMethod("rf_pfn")
}

#' @export
#' @rdname rf_pfn
rf_pfn.default <- function(x, ...) {
  cli::cli_abort("{.fn rf_pfn} is not defined for {obj_type_friendly(x)}.")
}

# XY method - data frame

#' @export
#' @rdname rf_pfn
rf_pfn.data.frame <- function(
  x,
  y,
  tree_type              = c("random_forest", "decision_tree"),
  num_estimators         = 8L,
  softmax_temperature    = 0.9,
  balance_probabilities  = FALSE,
  average_before_softmax = FALSE,
  max_depth              = 5L,
  min_samples_split      = 1000L,
  min_samples_leaf       = 5L,
  max_features           = "sqrt",
  fit_nodes              = TRUE,
  dt_average_logits      = TRUE,
  bootstrap              = NULL,
  rf_average_logits      = NULL,
  max_predict_time       = NULL,
  training_set_limit     = 10000,
  control                = control_tab_pfn(),
  ...
) {
  tree_type <- rlang::arg_match(tree_type)

  options <- control
  options$n_estimators           <- num_estimators
  options$softmax_temperature    <- softmax_temperature
  options$balance_probabilities  <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  rf_opts <- list(
    max_depth         = max_depth,
    min_samples_split = min_samples_split,
    min_samples_leaf  = min_samples_leaf,
    max_features      = max_features,
    fit_nodes         = fit_nodes,
    dt_average_logits = dt_average_logits,
    bootstrap         = bootstrap,
    rf_average_logits = rf_average_logits,
    max_predict_time  = max_predict_time
  )
  rf_opts <- check_rf_pfn_args(tree_type, rf_opts)

  processed <- hardhat::mold(x, y)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes   <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  rf_pfn_bridge(processed, tree_type, options, rf_opts, ...)
}

# XY method - matrix

#' @export
#' @rdname rf_pfn
rf_pfn.matrix <- function(
  x,
  y,
  tree_type              = c("random_forest", "decision_tree"),
  num_estimators         = 8L,
  softmax_temperature    = 0.9,
  balance_probabilities  = FALSE,
  average_before_softmax = FALSE,
  max_depth              = 5L,
  min_samples_split      = 1000L,
  min_samples_leaf       = 5L,
  max_features           = "sqrt",
  fit_nodes              = TRUE,
  dt_average_logits      = TRUE,
  bootstrap              = NULL,
  rf_average_logits      = NULL,
  max_predict_time       = NULL,
  training_set_limit     = 10000,
  control                = control_tab_pfn(),
  ...
) {
  tree_type <- rlang::arg_match(tree_type)

  options <- control
  options$n_estimators           <- num_estimators
  options$softmax_temperature    <- softmax_temperature
  options$balance_probabilities  <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  rf_opts <- list(
    max_depth         = max_depth,
    min_samples_split = min_samples_split,
    min_samples_leaf  = min_samples_leaf,
    max_features      = max_features,
    fit_nodes         = fit_nodes,
    dt_average_logits = dt_average_logits,
    bootstrap         = bootstrap,
    rf_average_logits = rf_average_logits,
    max_predict_time  = max_predict_time
  )
  rf_opts <- check_rf_pfn_args(tree_type, rf_opts)

  processed <- hardhat::mold(x, y)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes   <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  rf_pfn_bridge(processed, tree_type, options, rf_opts, ...)
}

# Formula method

#' @export
#' @rdname rf_pfn
rf_pfn.formula <- function(
  formula,
  data,
  tree_type              = c("random_forest", "decision_tree"),
  num_estimators         = 8L,
  softmax_temperature    = 0.9,
  balance_probabilities  = FALSE,
  average_before_softmax = FALSE,
  max_depth              = 5L,
  min_samples_split      = 1000L,
  min_samples_leaf       = 5L,
  max_features           = "sqrt",
  fit_nodes              = TRUE,
  dt_average_logits      = TRUE,
  bootstrap              = NULL,
  rf_average_logits      = NULL,
  max_predict_time       = NULL,
  training_set_limit     = 10000,
  control                = control_tab_pfn(),
  ...
) {
  tree_type <- rlang::arg_match(tree_type)

  options <- control
  options$n_estimators           <- num_estimators
  options$softmax_temperature    <- softmax_temperature
  options$balance_probabilities  <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  rf_opts <- list(
    max_depth         = max_depth,
    min_samples_split = min_samples_split,
    min_samples_leaf  = min_samples_leaf,
    max_features      = max_features,
    fit_nodes         = fit_nodes,
    dt_average_logits = dt_average_logits,
    bootstrap         = bootstrap,
    rf_average_logits = rf_average_logits,
    max_predict_time  = max_predict_time
  )
  rf_opts <- check_rf_pfn_args(tree_type, rf_opts)

  bp <- hardhat::default_formula_blueprint(
    intercept          = FALSE,
    allow_novel_levels = FALSE,
    indicators         = "none",
    composition        = "tibble"
  )
  processed <- hardhat::mold(formula, data, blueprint = bp)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes   <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  rf_pfn_bridge(processed, tree_type, options, rf_opts, ...)
}

# Recipe method

#' @export
#' @rdname rf_pfn
rf_pfn.recipe <- function(
  x,
  data,
  tree_type              = c("random_forest", "decision_tree"),
  num_estimators         = 8L,
  softmax_temperature    = 0.9,
  balance_probabilities  = FALSE,
  average_before_softmax = FALSE,
  max_depth              = 5L,
  min_samples_split      = 1000L,
  min_samples_leaf       = 5L,
  max_features           = "sqrt",
  fit_nodes              = TRUE,
  dt_average_logits      = TRUE,
  bootstrap              = NULL,
  rf_average_logits      = NULL,
  max_predict_time       = NULL,
  training_set_limit     = 10000,
  control                = control_tab_pfn(),
  ...
) {
  tree_type <- rlang::arg_match(tree_type)

  options <- control
  options$n_estimators           <- num_estimators
  options$softmax_temperature    <- softmax_temperature
  options$balance_probabilities  <- balance_probabilities
  options$average_before_softmax <- average_before_softmax
  options <- check_fit_args(options)
  check_number_whole(training_set_limit, min = 2, allow_infinite = TRUE)

  rf_opts <- list(
    max_depth         = max_depth,
    min_samples_split = min_samples_split,
    min_samples_leaf  = min_samples_leaf,
    max_features      = max_features,
    fit_nodes         = fit_nodes,
    dt_average_logits = dt_average_logits,
    bootstrap         = bootstrap,
    rf_average_logits = rf_average_logits,
    max_predict_time  = max_predict_time
  )
  rf_opts <- check_rf_pfn_args(tree_type, rf_opts)

  processed <- hardhat::mold(x, data)
  tr_ind <- sample_indicies(processed, size_limit = training_set_limit)
  if (length(tr_ind) > 0) {
    processed$predictors <- processed$predictors[tr_ind, , drop = FALSE]
    processed$outcomes   <- processed$outcomes[tr_ind, , drop = FALSE]
  }

  rf_pfn_bridge(processed, tree_type, options, rf_opts, ...)
}

# ------------------------------------------------------------------------------
# Bridge

rf_pfn_bridge <- function(processed, tree_type, options, rf_opts, ...) {
  rlang::check_dots_empty()

  predictors <- processed$predictors
  outcome    <- processed$outcomes[[1]]

  check_data_constraints(predictors, outcome, options)

  res <- rf_pfn_impl(predictors, outcome, tree_type, options, rf_opts)

  new_rf_pfn(
    fit       = res$fit,
    levels    = res$lvls,
    training  = res$train,
    logging   = res$logging,
    tree_type = tree_type,
    blueprint = processed$blueprint
  )
}

# ------------------------------------------------------------------------------
# Implementation

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
  rf_wrapper    <- function(...) ext_lib$rf_pfn[[py_class_name]](...)

  # RandomForestTabPFNRegressor has no dt_average_logits; DT classes call
  # the same parameter average_logits instead.
  if (tree_type == "random_forest" && !is.factor(y)) {
    rf_opts <- rf_opts[names(rf_opts) != "dt_average_logits"]
  } else if (tree_type == "decision_tree") {
    names(rf_opts)[names(rf_opts) == "dt_average_logits"] <- "average_logits"
  }

  # 4. Instantiate the RF/DT model and fit it. RF-PFN requires 0-based integer
  #    class labels; predict_proba fails if strings are stored in classes_.
  #    We pass 0-based codes and rely on object$levels for the back-mapping.
  mod_obj <- rlang::eval_bare(rlang::call2("rf_wrapper", !!!rf_opts))

  if (is.factor(y)) {
    y_fit <- as.integer(y) - 1L
  } else {
    y_fit <- y
  }

  py_msg <- reticulate::py_capture_output(
    model_fit <- try(mod_obj$fit(x, y_fit), silent = TRUE)
  )

  if (inherits(model_fit, "try-error")) {
    msgs <- as.character(model_fit)
    cli::cli_abort("Model failed: {msgs}")
  } else {
    msgs <- character(0)
  }

  list(
    fit     = model_fit,
    lvls    = levels(y),
    train   = dim(x),
    logging = c(r = msgs, py = py_msg)
  )
}

#' @export
print.rf_pfn <- function(x, ...) {
  if (x$tree_type == "random_forest") {
    tree_label <- "Random Forest"
  } else {
    tree_label <- "Decision Tree"
  }
  if (is.null(x$levels)) {
    type_label <- "Regression"
  } else {
    type_label <- "Classification"
  }
  cli::cli_inform("RF-PFN {tree_label} {type_label} Model")
  cat("\n")
  cli::cli_inform("Training set\n\n")
  cli::cli_inform(c(i = "{x$training[1]} data point{?s}"))
  cli::cli_inform(c(i = "{x$training[2]} predictor{?s}"))

  if (!is.null(x$levels)) {
    cli::cli_inform(c(i = "class levels: {.val {x$levels}}"))
  }

  invisible(x)
}

# ------------------------------------------------------------------------------
# Argument validation

check_rf_pfn_args <- function(tree_type, opts, call = rlang::caller_env()) {
  if (tree_type == "decision_tree") {
    rf_only <- c("bootstrap", "rf_average_logits", "max_predict_time")
    for (param in rf_only) {
      if (!is.null(opts[[param]])) {
        cli::cli_abort(
          "{.arg {param}} is not supported for {.code tree_type = \"decision_tree\"}.",
          call = call
        )
      }
    }
  }

  check_number_whole(
    opts$max_depth,
    arg        = "max_depth",
    min        = 1,
    allow_null = TRUE,
    call       = call
  )
  check_number_whole(
    opts$min_samples_split,
    arg  = "min_samples_split",
    min  = 1,
    call = call
  )
  check_number_whole(
    opts$min_samples_leaf,
    arg  = "min_samples_leaf",
    min  = 1,
    call = call
  )
  check_logical(opts$fit_nodes,         arg = "fit_nodes",         call = call)
  check_logical(opts$dt_average_logits, arg = "dt_average_logits", call = call)

  if (!is.null(opts$bootstrap)) {
    check_logical(opts$bootstrap, arg = "bootstrap", call = call)
  }
  if (!is.null(opts$rf_average_logits)) {
    check_logical(opts$rf_average_logits, arg = "rf_average_logits", call = call)
  }
  if (!is.null(opts$max_predict_time)) {
    check_number_decimal(opts$max_predict_time, arg = "max_predict_time", call = call)
  }

  if (!is.null(opts$max_features)) {
    if (!is.character(opts$max_features) && !is.numeric(opts$max_features)) {
      cli::cli_abort(
        "{.arg max_features} must be a string, a number, or {.code NULL}.",
        call = call
      )
    }
  }

  if (!is.null(opts$max_depth)) {
    opts$max_depth <- as.integer(opts$max_depth)
  }
  opts$min_samples_split <- as.integer(opts$min_samples_split)
  opts$min_samples_leaf  <- as.integer(opts$min_samples_leaf)

  opts
}
