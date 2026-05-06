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
