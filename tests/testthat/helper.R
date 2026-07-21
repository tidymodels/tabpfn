skip_if_no_tabpfn <- function() {
  skip_if(
    !is_tab_pfn_installed(),
    message = "TabPFN Python library is not installed"
  )
  skip_on_cran()
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
