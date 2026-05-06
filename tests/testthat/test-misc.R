test_that("list_tabpfn_versions returns a character vector", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  versions <- list_tabpfn_versions()
  expect_type(versions, "character")
  expect_gt(length(versions), 0)
})

test_that("list_tabpfn_versions includes known versions", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  versions <- list_tabpfn_versions()
  expect_contains(versions, "v2")
})

test_that("check_model_version validates correctly", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  expect_no_error(check_model_version("v2"))
  expect_no_error(check_model_version("v2.5"))
  expect_error(check_model_version("V2"), "not a valid model version")
  expect_error(check_model_version("invalid"), "not a valid model version")
})

test_that('data constraints', {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()
  skip_if_not_installed("modeldata")

  set.seed(418)
  orig_data <- tab_pfn(
    Class ~ .,
    data = modeldata::two_class_dat,
    num_estimators = 1,
  )

  expect_equal(orig_data$training[1], nrow(modeldata::two_class_dat))

  set.seed(418)
  smaller_data <- tab_pfn(
    Class ~ .,
    data = modeldata::two_class_dat,
    num_estimators = 1,
    training_set_limit = 50,
    control = control_tab_pfn(ignore_pretraining_limits = TRUE)
  )

  expect_equal(smaller_data$training[1], 50)
})
