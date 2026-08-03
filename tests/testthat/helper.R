skip_if_no_tabpfn <- function() {
  skip_if(
    !is_tab_pfn_installed(),
    message = "TabPFN Python library is not installed"
  )
  skip_on_cran()
}

# Force TabPFN onto CPU for the duration of the calling test so the printed
# device is deterministic across hardware. TabPFN reads TABPFN_EXCLUDE_DEVICES
# from Python's `os.environ`, which R's Sys.setenv() does not reach, so it is
# set directly on the Python side and restored on exit.
local_tabpfn_cpu <- function(.local_envir = parent.frame()) {
  os <- reticulate::import("os")
  key <- "TABPFN_EXCLUDE_DEVICES"
  old <- os$environ$get(key)
  reticulate::py_set_item(os$environ, key, "cuda,mps")
  withr::defer(
    if (is.null(old)) {
      reticulate::py_del_item(os$environ, key)
    } else {
      reticulate::py_set_item(os$environ, key, old)
    },
    envir = .local_envir
}
    
# Gate for tests that actually create/modify a Python environment. These are
# slow and network-bound, so they only run when explicitly opted in.
skip_if_not_installing <- function() {
  skip_on_cran()
  skip_on_ci()
  skip_if(
    Sys.getenv("TABPFN_TEST_INSTALL") != "true",
    message = "set TABPFN_TEST_INSTALL=true to run install tests"
  )
}

exp_cls <- c("tabpfn", "hardhat_model", "hardhat_scalar")

predictors <- mtcars[, -1]
outcome <- mtcars[, 1]
