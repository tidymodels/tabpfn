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
