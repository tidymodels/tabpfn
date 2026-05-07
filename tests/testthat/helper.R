skip_if_no_tabpfn <- function() {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()
}

exp_cls <- c("tabpfn", "hardhat_model", "hardhat_scalar")

predictors <- mtcars[, -1]
outcome <- mtcars[, 1]
