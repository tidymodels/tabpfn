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

# Is reticulate's resolved Python the canonical `"r-tabpfn"` environment? Used
# by `.onLoad()` to decide whether to eagerly import `tabpfn` (see #34).
uses_canonical_env <- function(envname = "r-tabpfn") {
  exe <- tryCatch(reticulate::py_exe(), error = function(e) NULL)
  if (is.null(exe) || !nzchar(exe)) {
    return(FALSE)
  }

  norm <- function(p) {
    if (is.null(p) || !nzchar(p)) {
      return(NULL)
    }
    tryCatch(normalizePath(p, mustWork = FALSE), error = function(e) p)
  }

  exe <- norm(exe)

  venv <- NULL
  if (reticulate::virtualenv_exists(envname)) {
    venv <- norm(reticulate::virtualenv_python(envname))
  }
  conda <- tryCatch(
    norm(reticulate::conda_python(envname)),
    error = function(e) NULL
  )

  identical(exe, venv) || identical(exe, conda)
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
        "!" = "In a new R session, run {.code tabpfn::tabpfn_initialize()} before loading {.pkg tabpfn} or any other package.",
        call = NULL
      )
    )
  }
  invisible(NULL)
}

# ------------------------------------------------------------------------------

# The data limits of each model version.
#
# `rows_gpu`, `predictors` and `classes` mirror `MAX_NUMBER_OF_SAMPLES`,
# `MAX_NUMBER_OF_FEATURES` and `MAX_NUMBER_OF_CLASSES` on the Python
# `InferenceConfig`. `rows_cpu` mirrors `MAX_CPU_SAMPLES`, which comes from
# `tabpfn.inference_config.cpu_sample_limit()` and is a far lower ceiling that
# applies when the fit runs on a CPU.
#
# HOW TO UPDATE, when a new model version ships:
#
#   * Read the numbers off a fitted model, do not copy them from
#     <https://docs.priorlabs.ai/models>. The site and the library disagree:
#     the site lists 100K rows for v2.5, the library reports 50K.
#
#       m <- tab_pfn(mtcars[, -1], mtcars[, 1], version = "v3.5")
#       m$fit$inference_config_$MAX_NUMBER_OF_SAMPLES
#
#   * One row per version, even where the numbers repeat. A row is one fact
#     about one version.
#
#   * An entry must be exact or absent. `NA` means "we do not know", which
#     approves and lets Python decide. Being too permissive is cheap, because
#     Python catches it; being too strict rejects work that would have
#     succeeded.
#
# Nothing in the package enforces these numbers: the Python library does that,
# and raises its own error. The table exists so `?tab_pfn` can show the limits
# without anyone retyping them. `test-misc.R` checks it against a live model
# for every version it lists, so a stale entry fails there rather than in the
# help page.
tabpfn_limits <- tibble::tribble(
  ~version,    ~rows_gpu, ~rows_cpu, ~predictors, ~classes,
  "v3.5-fast", 1000000,   5000,      20000,       160,
  "v3.5",      1000000,   5000,      20000,       160,
  "v3",        1000000,   5000,      2000,        160,
  "v2.6",      100000,    1000,      2000,        10,
  "v2.5",      50000,     1000,      2000,        10,
  "v2",        10000,     1000,      500,         10
)

# 1000 -> "1K", 1e6 -> "1M", for the documentation table.
abbreviate_count <- function(x) {
  if (is.na(x)) {
    return("unknown")
  }
  if (x >= 1e6) {
    return(paste0(x / 1e6, "M"))
  }
  if (x >= 1000) {
    return(paste0(x / 1000, "K"))
  }
  as.character(x)
}

# Renders `tabpfn_limits` as roxygen markdown, so the help page cannot drift
# from the table. Called from `@eval`.
limits_table_md <- function() {
  fmt <- function(x) {
    purrr::map_chr(x, abbreviate_count)
  }

  rows <- paste0(
    "| `\"",
    tabpfn_limits$version,
    "\"` | ",
    fmt(tabpfn_limits$rows_gpu),
    " | ",
    fmt(tabpfn_limits$rows_cpu),
    " | ",
    fmt(tabpfn_limits$predictors),
    " | ",
    fmt(tabpfn_limits$classes),
    " |"
  )

  c(
    "@section Data limits by version:",
    "",
    "| Version | Rows (GPU) | Rows (CPU) | Predictors | Classes |",
    "| --- | --- | --- | --- | --- |",
    rows,
    "",
    "The CPU column is not advice. TabPFN refuses a CPU fit above that many",
    "rows, whatever the version's own limit says, so `\"v3.5\"` stops at 5,000",
    "rows on a machine without a GPU. Set `ignore_pretraining_limits = TRUE`",
    "in [control_tab_pfn()], or the `TABPFN_ALLOW_CPU_LARGE_DATASET`",
    "environment variable, to lift it. The fit then runs, slowly.",
    "",
    "Every limit here is enforced by the Python library, which raises an error",
    "naming the count and the limit. Use `training_set_limit` to fit on a",
    "sample instead.",
    "",
    "The row and predictor maxima trade off against each other, so you cannot",
    "always reach both at once. The ceiling is not a promise either: for",
    "`\"v3.5\"`, PriorLabs recommends up to 6,000 predictors even though the",
    "model tops out at 20,000. See <https://docs.priorlabs.ai/models>."
  )
}

# Sampling down the data when the user asks for a smaller training set.

sample_indicies <- function(molded, size_limit) {
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
  suppressWarnings(
    res <- import_tabpfn() |>
      reticulate::py_has_attr("noexists") |> # Forcing load of package
      try(silent = TRUE)
  )
  !inherits(res, "try-error")
}


# Normalizes a user-supplied model version. Users may pass a bare number
# (e.g. `2.5` or `"2.5"`); we prefix a `v` so it matches the `v`-prefixed
# strings the Python library expects. The prefix is only added when the value
# does not already start with `v`, and matching remains exact, so a bare `2.5`
# will never match something like `v2.5-turbo` unless `v2.5` itself exists.
normalize_model_version <- function(x) {
  if (is.null(x)) {
    return(x)
  }

  if (is.numeric(x)) {
    x <- format(x, trim = TRUE)
  }

  if (is.character(x) && !grepl("^v", x)) {
    x <- paste0("v", x)
  }

  x
}


check_model_version <- function(x, call = rlang::caller_env()) {
  valid_versions <- tabpfn_list_versions()

  if (!x %in% valid_versions) {
    cli::cli_abort(
      c(
        "{.arg model_version} must be one of {.or {.val {valid_versions}}}.",
        x = "{.val {x}} is not a valid model version."
      ),
      call = call
    )
  }

  invisible(x)
}
