#' Predict using an RF-PFN model
#'
#' @param object,x An `rf_pfn` object.
#'
#' @param new_data A data frame or matrix of new predictors.
#'
#' @param ... Not used, but required for extensibility.
#'
#' @return
#'
#' [predict()] returns a tibble of predictions and [augment()] appends the
#' columns in `new_data`. In either case, the number of rows in the tibble is
#' guaranteed to be the same as the number of rows in `new_data`.
#'
#' For regression, the prediction is in the column `.pred`. For classification,
#' the class predictions are in `.pred_class` and the probability estimates are
#' in columns with the pattern `.pred_{level}` where `level` is the levels of
#' the outcome factor vector.
#'
#' @examples
#' car_train <- mtcars[ 1:5,   ]
#' car_test  <- mtcars[6, -1]
#'
#' \dontrun{
#' if (is_tab_pfn_installed() & interactive()) {
#'  mod <- rf_pfn(mpg ~ cyl + log(drat), car_train)
#'
#'  predict(mod, car_test)
#'  augment(mod, car_test)
#' }
#' }
#'
#' @export
predict.rf_pfn <- function(object, new_data, ...) {
  rlang::check_dots_empty()
  forged <- hardhat::forge(new_data, object$blueprint)$predictors

  if (is.null(object$levels)) {
    py_msg <- reticulate::py_capture_output(
      res <- try(object$fit$predict(forged), silent = TRUE)
    )

    if (inherits(res, "try-error")) {
      msgs <- as.character(res)
      cli::cli_abort("Prediction failed: {msgs}")
    }

    tibble::tibble(.pred = as.vector(res))
  } else {
    py_msg <- reticulate::py_capture_output(
      res <- try(object$fit$predict_proba(forged), silent = TRUE)
    )

    if (inherits(res, "try-error")) {
      msgs <- as.character(res)
      cli::cli_abort("Prediction failed: {msgs}")
    }

    # classes_ are 0-based integers; map back to original level names via levels
    class_names <- object$levels[as.integer(object$fit$classes_) + 1L]
    colnames(res) <- paste0(".pred_", class_names)
    cls_ind <- apply(res, 1, which.max)
    res <- tibble::as_tibble(res)
    res$.pred_class <- factor(class_names[cls_ind], levels = object$levels)
    res
  }
}

#' @export
#' @rdname predict.rf_pfn
augment.rf_pfn <- function(x, new_data, ...) {
  new_data <- tibble::new_tibble(new_data)
  res      <- predict(x, new_data)
  res      <- cbind(res, new_data)
  tibble::new_tibble(res)
}
