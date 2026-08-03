# nocov start
.pkg_env <- new.env()
.pkg_env$tab_pfn <- NULL

.onLoad <- function(...) {
  # Set PyTorch TorchInductor cache to R's temp directory
  # This prevents 'torchinductor' directory creation in working directory
  if (Sys.getenv("TORCHINDUCTOR_CACHE_DIR") == "") {
    torch_cache_dir <- file.path(tempdir(), "torchinductor")
    Sys.setenv(TORCHINDUCTOR_CACHE_DIR = torch_cache_dir)
  }

  reticulate::py_require("tabpfn")

  tryCatch(
    .pkg_env$tab_pfn <- reticulate::import(
      "tabpfn",
      delay_load = list(
        on_error = function(e) {
          cli::cli_abort(msg_tabpfn_not_available(e))
        },
        # See https://github.com/tidymodels/tabpfn/issues/3
        before_load = function() {
          check_libomp()
        }
      )
    ),

    # if reticulate has already loaded symbols from a Python installation,
    # `reticulate::import(delay_load = TRUE)` will error immediately.
    python.builtin.ModuleNotFoundError = function(e) {
      cli::cli_warn(msg_tabpfn_not_available(e))
    }
  )

  # The `delay_load` above defers the real Python import (and torch grabbing
  # its bundled libomp) until the first use of `tab_pfn()`. By then a foreign
  # OpenMP may already be loaded, causing the segfault described in #34.
  #
  # The `tryCatch()` above forces reticulate to resolve which Python it will
  # use, so `py_exe()` is now known. When that Python is the canonical
  # `"r-tabpfn"` environment (i.e. a deliberate `install_tabpfn()`), eagerly
  # import `tabpfn` now so torch claims libomp before any other package can.
  if (uses_canonical_env()) {
    tryCatch(
      {
        check_libomp()
        .pkg_env$tab_pfn <- reticulate::import("tabpfn")
      },
      error = function(e) {
        cli::cli_warn(msg_tabpfn_not_available(e))
      }
    )
  }
}

.onUnload <- function(libpath) {
  # Clean up any torchinductor directories that may have been created
  # This is a defensive measure in case the environment variable didn't work

  # Check current working directory
  torch_dir_cwd <- file.path(getwd(), "torchinductor")
  if (dir.exists(torch_dir_cwd)) {
    unlink(torch_dir_cwd, recursive = TRUE, force = TRUE)
  }

  # Clean up in R CMD check temp directories (paths containing .Rcheck)
  if (grepl("\\.Rcheck", getwd(), fixed = TRUE)) {
    torch_dirs <- list.files(
      path = getwd(),
      pattern = "^torchinductor$",
      full.names = TRUE,
      recursive = FALSE,
      include.dirs = TRUE
    )
    for (dir in torch_dirs) {
      if (dir.exists(dir)) {
        unlink(dir, recursive = TRUE, force = TRUE)
      }
    }
  }
}

import_tabpfn <- function() {
  .pkg_env$tab_pfn
}

# nocov end

#' Eagerly initialize the TabPFN Python library
#'
#' @description
#' Forces the Python `tabpfn` library (and its PyTorch dependency) to load now
#' instead of on first use. Because PyTorch bundles its own OpenMP runtime,
#' loading it before any other package that uses OpenMP avoids the segmentation
#' fault described in \url{https://github.com/tidymodels/tabpfn/issues/34}.
#'
#' For this to work, call it as the very first thing in your session, using
#' `tabpfn::tabpfn_initialize()` (with the `::` prefix so it runs before
#' `library(tabpfn)` and before any other package that might load OpenMP, such
#' as \pkg{recipes}):
#'
#' ```r
#' tabpfn::tabpfn_initialize()
#' library(tabpfn)
#' suppressPackageStartupMessages(library(recipes))
#' fit_obj <- tab_pfn(mpg ~ ., data = mtcars)
#' ```
#'
#' @return `NULL`, invisibly. Called for its side effect of loading the Python
#'   library.
#' @examples
#' \dontrun{
#' tabpfn::tabpfn_initialize()
#' library(tabpfn)
#' }
#' @export
tabpfn_initialize <- function() {
  # Accessing an attribute of the module proxy is what actually materializes
  # the Python import; `tabpfn_list_versions()` does this reliably. We call it
  # only for that side effect and discard the result.
  suppressMessages(tabpfn_list_versions())
  invisible(NULL)
}
