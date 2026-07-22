test_that("tab_pfn fits with all versions", {
  skip_if_no_tabpfn()
  for (version in tabpfn_list_versions()) {
    mod <- tab_pfn(am ~ mpg + wt, data = mtcars, version = version)
    expect_s3_class(mod, "tab_pfn")
  }
})

test_that("tab_pfn records the model version", {
  skip_if_no_tabpfn()
  mod <- tab_pfn(am ~ mpg + wt, data = mtcars, version = "v2")
  expect_type(mod$version, "character")
  expect_length(mod$version, 1)
  expect_false(is.na(mod$version))
  expect_true(nzchar(mod$version))
})

test_that("extract_model_version falls back to 'unknown' softly", {
  # An object without the expected python internals must not error.
  expect_identical(tabpfn:::extract_model_version(list()), "unknown")
  expect_identical(tabpfn:::extract_model_version(NULL), "unknown")
})

test_that("tab_pfn records the fitting device", {
  skip_if_no_tabpfn()
  mod <- tab_pfn(am ~ mpg + wt, data = mtcars, version = "v2")
  expect_type(mod$device, "character")
  expect_true(length(mod$device) >= 1)
  expect_false(anyNA(mod$device))
  expect_true(all(nzchar(mod$device)))
})

test_that("extract_model_device falls back to 'unknown' softly", {
  # An object without the expected python internals must not error.
  expect_identical(tabpfn:::extract_model_device(list()), "unknown")
  expect_identical(tabpfn:::extract_model_device(NULL), "unknown")
})

test_that("check_data_constraints errors when too many rows", {
  x <- matrix(0, nrow = 50001, ncol = 2)
  y <- factor(rep(c("a", "b"), length.out = 50001))
  expect_error(
    tabpfn:::check_data_constraints(x, y, control_tab_pfn()),
    "50,000"
  )
})

test_that("tab_pfn v2 errors with more than 500 predictors", {
  skip_if_no_tabpfn()
  n <- 100
  x <- as.data.frame(matrix(rnorm(n * 501), nrow = n, ncol = 501))
  x$y <- factor(rep(c("a", "b"), length.out = n))
  expect_error(
    tab_pfn(y ~ ., data = x, version = "v2")
  )
})

test_that("check_data_constraints errors when too many columns", {
  x <- matrix(0, nrow = 10, ncol = 2001)
  y <- factor(rep(c("a", "b"), length.out = 10))
  expect_error(
    tabpfn:::check_data_constraints(x, y, control_tab_pfn()),
    "2000"
  )
})

test_that("check_data_constraints errors when too many classes", {
  x <- matrix(0, nrow = 11, ncol = 2)
  y <- factor(letters[1:11])
  expect_error(
    tabpfn:::check_data_constraints(x, y, control_tab_pfn()),
    "classes"
  )
})

test_that("sample_indicies handles numeric outcomes", {
  set.seed(1)
  molded <- list(outcomes = data.frame(outcome = rnorm(50001)))
  result <- tabpfn:::sample_indicies(molded)
  expect_length(result, 50000)
  expect_true(all(result >= 1 & result <= 50001))
})

test_that("data constraints", {
  skip_if_no_tabpfn()
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
