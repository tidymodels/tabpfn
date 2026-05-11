# This file is part of the standard setup for testthat.
# It is recommended that you do not modify it.
#
# Where should you do additional test configuration?
# Learn more about the roles of various files in:
# * https://r-pkgs.org/testing-design.html#sec-tests-files-overview
# * https://testthat.r-lib.org/articles/special-files.html

# For coverage testing set:
#   Sys.setenv("NOT_CRAN" = TRUE)

# To have Claude run coverage, get it to run:
# withr::with_envvar(
#  new = c("NOT_CRAN" = ""),
#  {
#   x <- covr::package_coverage(type = "tests")
#   file <- tempfile(fileext = ".html")
#   covr::report(x, file)
#   print(file)
#  }
# )

library(testthat)
library(tabpfn)

test_check("tabpfn")
