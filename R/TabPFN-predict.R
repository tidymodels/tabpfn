#' Predict using `TabPFN`
#'
#' @param object,x A `tab_pfn` object.
#'
#' @param new_data A data frame or matrix of new predictors.
#'
#' @param type The type of prediction. For classification, can be `"class"` or
#' `"prob"`. Defaults to `NULL` which gives all prediction types possible. For
#' regression, can be `"mean"` or `"quantile"`; when `"quantile"`,
#' `quantile_levels` must be supplied.
#'
#' @param quantile_levels A numeric vector of probabilities, sorted in
#' increasing order, at which to predict the outcome distribution. Regression
#' only; required when `type = "quantile"` and must otherwise be `NULL`.
#'
#' @param ... Not used, but required for extensibility.
#'
#' @return
#'
#' [predict()] returns a tibble of predictions and [augment()] appends the
#' columns in `new_data`. In either case, the number of rows in the tibble is
#' guaranteed to be the same as the number of rows in `new_data`.
#'
#' For regression data, the prediction is in the column `.pred`. For
#' classification, the class predictions are in `.pred_class` and the
#' probability estimates are in columns with the pattern `.pred_{level}` where
#' `level` is the levels of the outcome factor vector.
#'
#' When `quantile_levels` is given, regression results also have a
#' `.pred_quantile` column of [hardhat::quantile_pred()] values.
#'
#' @examples
#' \dontrun{
#' if (rlang::is_installed(c("MASS", "ggplot2")) &
#'      is_tab_pfn_installed() &
#'      interactive()) {
#'   library(ggplot2)
#'
#'   in_tr <- seq(1, nrow(mcycle), by = 2)
#'   mcycle_tr <- MASS::mcycle[in_tr, ]
#'   mcycle_te <- MASS::mcycle[-in_tr, ]
#'
#'   mcycle_grid <-
#'    dplyr::tibble(times = seq(min(mcycle$times), max(mcycle$times), length.out = 200))
#'   mcycle_grid$.row <- seq_len(nrow(mcycle_grid))
#'
#'   fit <- tab_pfn(accel ~ times, data = mcycle_tr)
#'
#'   # ------------------------------------------------------------------------------
#'   # Predict mean acceleration
#'
#'   mean_pred <- augment(fit, mcycle_grid)
#'
#'   mean_p <-
#'    mean_pred |>
#'    ggplot(aes(times)) +
#'    geom_point(data = mcycle_te, aes(y = accel), alpha = 1 / 2) +
#'    geom_line(aes(y = .pred))
#'
#'   #------------------------------------------------------------------------------Predict 5 %, 50%
#'   # Predict 5%, 50%, and 90% quantiles of acceleration
#'
#'   q_pred <-
#'    predict(fit,
#'            mcycle_grid,
#'            type = "quantile",
#'            quantile_levels = c(0.1, 0.5, 0.9))
#'   q_pred$.row <- seq_len(nrow(q_pred))
#'
#'   q_pred_longer <-
#'    q_pred$.pred_quantile |>
#'    dplyr::as_tibble() |>
#'    dplyr::full_join(mcycle_grid, by = ".row") |>
#'    dplyr::mutate(level = format(.quantile_levels))
#'
#'   mean_p +
#'    geom_line(
#'      data = q_pred_longer,
#'      aes(y = .pred_quantile, col = level, group = level)
#'    )
#' }
#' }
#' @export
predict.tab_pfn <- function(
  object,
  new_data,
  type = NULL,
  quantile_levels = NULL,
  ...
) {
  rlang::check_dots_empty()
  if (!is.null(quantile_levels) && !is.null(object$levels)) {
    cli::cli_abort("{.arg quantile_levels} is only for regression models.")
  }
  if (is.null(object$levels)) {
    if (is.null(type)) {
      type <- "mean"
    }
    type <- rlang::arg_match(type, c("mean", "quantile"))

    if (identical(type, "quantile") && is.null(quantile_levels)) {
      cli::cli_abort(
        "{.arg quantile_levels} must be supplied when {.code type = \"quantile\"}."
      )
    }

    if (!identical(type, "quantile") && !is.null(quantile_levels)) {
      cli::cli_abort(
        "{.arg quantile_levels} can only be supplied when {.code type = \"quantile\"}."
      )
    }
  }
  if (!is.null(quantile_levels)) {
    hardhat::check_quantile_levels(quantile_levels)
  }
  forged <- hardhat::forge(new_data, object$blueprint)$predictors
  res <- predict(
    object$fit,
    forged,
    object$levels,
    type = type,
    quantile_levels = unname(quantile_levels)
  )
  res
}

# ------------------------------------------------------------------------------
# Implementation

#' @export
predict.tabpfn.regressor.TabPFNRegressor <- function(
  object,
  new_data,
  levels,
  type = NULL,
  quantile_levels = NULL,
  ...
) {
  py_msg <- reticulate::py_capture_output(
    res <- try(
      object$predict(
        new_data,
        output_type = if (is.null(quantile_levels)) "mean" else "main",
        quantiles = as.list(quantile_levels)
      ),
      silent = TRUE
    )
  )

  if (inherits(res, "try-error")) {
    msgs <- as.character(res)
    cli::cli_abort("Prediction failed: {msgs}")
  } else if (is.null(quantile_levels)) {
    res <- tibble::tibble(.pred = as.vector(res))
  } else {
    res <- tibble::tibble(
      .pred = as.vector(res$mean),
      .pred_quantile = hardhat::quantile_pred(
        do.call(cbind, res$quantiles),
        quantile_levels
      )
    )
  }

  res
}

#' @export
predict.tabpfn.classifier.TabPFNClassifier <- function(
  object,
  new_data,
  levels,
  type = NULL,
  ...
) {
  py_msg <- reticulate::py_capture_output(
    res <- try(object$predict_proba(new_data), silent = TRUE)
  )

  if (inherits(res, "try-error")) {
    msgs <- as.character(res)
    cli::cli_abort("Prediction failed: {msgs}")
  } else {
    colnames(res) <- paste0(".pred_", object$classes_)
    cls_ind <- apply(res, 1, which.max)
    res <- tibble::as_tibble(res)
    # TabPFN will reorder the class levels; if the original factor has levels "b"
    # and "a", object$classes_ will have c("a", "b)
    res$.pred_class <- factor(object$classes_[cls_ind], levels = levels)
  }
  if (!is.null(type)) {
    type <- rlang::arg_match(type, c("class", "prob"))
    if (type == "class") {
      res <- res[, ".pred_class"]
    } else if (type == "prob") {
      res <- res[, names(res) != ".pred_class"]
    }
  }

  res
}

#' @export
#' @rdname predict.tab_pfn
augment.tab_pfn <- function(
  x,
  new_data,
  type = NULL,
  quantile_levels = NULL,
  ...
) {
  new_data <- tibble::new_tibble(new_data)
  res <- predict(x, new_data, type = type, quantile_levels = quantile_levels)
  res <- cbind(res, new_data)
  tibble::new_tibble(res)
}
