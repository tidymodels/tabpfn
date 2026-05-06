msg_tabpfn_not_available <- function(cnd) {
  c(
    x = "The {.pkg tabpfn} Python package is not installed in the discovered Python installation ({.file {reticulate::py_exe()}}).",
    i = 'Allow reticulate to automatically configure an ephemeral Python environment by
         removing the Python installation from the order of discovery and restarting the R session.
         See {.href [Order of Discovery](https://rstudio.github.io/reticulate/dev/articles/versions.html#order-of-discovery)} for more info.',
    # Or set env var {.code Sys.setenv("RETICULATE_USE_MANAGED_VENV" = "yes")}',
    i = 'Or install {.pkg tabpfn} into the selected Python environment by calling
        {.code reticulate::py_install("tabpfn")}'
  )
}

check_libomp <- function() {
  os_info <- Sys.info()[["sysname"]]
  if (os_info != "Darwin") {
    return(invisible(NULL))
  }

  vm_types <- system(paste("vmmap", Sys.getpid()), intern = TRUE)
  libomp_lines <- grep("libomp", vm_types, value = TRUE)

  if (length(libomp_lines) == 0) {
    return(invisible(NULL))
  }

  # Extract the file path from each vmmap line (path starts with "/" at end of line)
  libomp_paths <- sub(".*\\s(/\\S+)\\s*$", "\\1", libomp_lines)

  # libomp loaded from within the active Python environment is fine — torch will
  # reuse it. Only error if libomp came from outside the Python env (e.g. an R
  # package or an OpenMP-enabled R binary), because torch would then try to load
  # its own bundled copy alongside a foreign one, causing a segfault.
  py_env_root <- reticulate::py_config()$prefix
  outside_py_env <- !startsWith(libomp_paths, py_env_root)

  if (any(outside_py_env)) {
    cli::cli_abort(
      c(
        i = "We believe that an existing package has loaded {.pkg OpenMP}.",
        x = "{.pkg PyTorch} was about to do the same and would cause a segmentation fault.",
        i = "See {.url https://github.com/tidymodels/tabpfn/issues/3}.",
        "!" = "Try running {.code reticulate::import('torch')} in a new R session prior to loading other packages.",
        call = NULL
      )
    )
  }
  invisible(NULL)
}

# ------------------------------------------------------------------------------

row_limits <- 50000
col_limits <- 2000
cls_limits <- 10

check_data_constraints <- function(x, y, control) {
  lvls <- levels(y)

  x_dims <- dim(x)
  if (x_dims[1] > row_limits & !control$ignore_pretraining_limits) {
    cli::cli_abort(
      call = NULL,
      c(
        i = "There are {format(x_dims[1], big.mark = ',')} rows in the training set.",
        i = "TabPFN (version 2) is intended for training set sizes <=
        {format(row_limits, big.mark = ',')} rows.",
        i = "Consider setting the option {.arg ignore_pretraining_limits} to
        {.val TRUE} or subset the training size using the
        {.arg training_set_limit} argument."
      )
    )
  }
  if (x_dims[2] > col_limits & !control$ignore_pretraining_limits) {
    cli::cli_abort(
      call = NULL,
      c(
        i = "There are {format(x_dims[2], big.mark = ',')} predictors in the training set.",
        i = "TabPFN (version 2) is intended for <= {col_limits} predictors.",
        i = "Consider setting the option {.arg ignore_pretraining_limits} to {.val TRUE} or subset the training size."
      )
    )
  }

  if (!is.null(lvls) && length(lvls) > cls_limits) {
    cli::cli_abort(
      call = NULL,
      c(
        i = "There are {length(lvls)} classes in the outcome.",
        x = "TabPFN (version 2) is intended for <= {cls_limits} classes and won't work with more."
      )
    )
  }

  invisible(NULL)
}

# Sampling down the data for data constraints

sample_indicies <- function(molded, size_limit = row_limits) {
  num_rows <- nrow(molded$outcomes)
  if (num_rows <= size_limit) {
    return(integer(0))
  }

  dat <-
    molded$outcomes |>
    dplyr::mutate(.row_order = dplyr::row_number()) |>
    rlang::set_names(c("outcome", ".row_order"))

  is_factor <- is.factor(dat$outcome)

  if (is_factor) {
    data_subset <-
      dat |>
      dplyr::group_by(outcome) |>
      dplyr::group_nest(keep = TRUE) |>
      dplyr::mutate(
        size = purrr::map_int(data, nrow),
        sample_prop = size / num_rows,
        sample_num = ceiling(sample_prop * size_limit),
        data = purrr::map2(data, sample_num, ~ dplyr::slice_sample(.x, n = .y))
      )
  } else {
    data_subset <-
      dat |>
      dplyr::mutate(quantile = dplyr::ntile(outcome, n = 4)) |>
      dplyr::group_by(quantile) |>
      dplyr::group_nest(keep = TRUE) |>
      dplyr::mutate(
        size = purrr::map_int(data, nrow),
        sample_prop = size / num_rows,
        sample_num = ceiling(sample_prop * size_limit),
        data = purrr::map2(data, sample_num, ~ dplyr::slice_sample(.x, n = .y))
      )
  }

  purrr::map_dfr(data_subset$data, ~.x) |>
    dplyr::arrange(.row_order) |>
    dplyr::select(.row_order) |>
    dplyr::slice(1:size_limit) |>
    purrr::pluck(".row_order")
}

#' Check the Python package installation
#'
#' Attempts to import the Python package
#' @return A single logical
#' @examples
#' if (interactive()) {
#'  # This may take a minute
#'  is_tab_pfn_installed()
#' }
#' @export
is_tab_pfn_installed <- function() {
  res <- try(reticulate::import("tabpfn"), silent = TRUE)
  !inherits(res, "try-error")
}
