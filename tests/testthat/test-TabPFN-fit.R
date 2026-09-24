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

test_that("sample_indicies handles numeric outcomes", {
  set.seed(1)
  molded <- list(outcomes = data.frame(outcome = rnorm(50001)))
  result <- tabpfn:::sample_indicies(molded, size_limit = 50000)
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

test_that("crop_training_set samples down to the limit", {
  molded <- hardhat::mold(mtcars[, -1], mtcars[, 1])

  out <- tabpfn:::crop_training_set(molded, training_set_limit = 10)
  expect_equal(nrow(out$outcomes), 10)
  expect_equal(nrow(out$predictors), 10)
})

test_that("crop_training_set leaves the data alone by default", {
  molded <- hardhat::mold(mtcars[, -1], mtcars[, 1])

  # `Inf` is the default, and nothing smaller than the data means no sampling.
  expect_identical(
    tabpfn:::crop_training_set(molded, training_set_limit = Inf),
    molded
  )
  expect_identical(
    tabpfn:::crop_training_set(molded, training_set_limit = nrow(mtcars)),
    molded
  )
})

test_that("tab_pfn uses every row unless told otherwise", {
  skip_if_no_tabpfn()

  fit <- tab_pfn(mtcars[, -1], mtcars[, 1], num_estimators = 1)
  expect_equal(fit$training[1], nrow(mtcars))

  smaller <- tab_pfn(
    mtcars[, -1],
    mtcars[, 1],
    num_estimators = 1,
    training_set_limit = 10
  )
  expect_equal(smaller$training[1], 10)
})

test_that("the Python library is what enforces the data limits", {
  skip_if_no_tabpfn()
  local_tabpfn_cpu()

  set.seed(1)
  n <- 5001
  d <- data.frame(y = rnorm(n), x1 = rnorm(n), x2 = rnorm(n))

  # v3.5 takes 1M rows, but only 5,000 of them on a CPU, and the refusal comes
  # from Python rather than from us.
  expect_error(
    tab_pfn(d[, -1], d$y, version = "v3.5", num_estimators = 1),
    "CPU"
  )

  # The same flag Python documents is what lets it through.
  expect_no_error(
    tab_pfn(
      d[, -1],
      d$y,
      version = "v3.5",
      num_estimators = 1,
      training_set_limit = 100,
      control = control_tab_pfn(ignore_pretraining_limits = TRUE)
    )
  )
})

test_that("clean_python_message strips the plumbing", {
  msg <- paste0(
    "tabpfn.errors.TabPFNValidationError: Number of samples `50,001` in the ",
    "input data is greater than the maximum number of samples `50,000` ",
    "officially supported by TabPFN. Set `ignore_pretraining_limits=True` to ",
    "override this error!\nRun `reticulate::py_last_error()` for details."
  )

  expect_equal(
    tabpfn:::clean_python_message(msg),
    paste0(
      "Number of samples `50,001` in the input data is greater than the ",
      "maximum number of samples `50,000` officially supported by TabPFN."
    )
  )
})

test_that("clean_python_message drops the footer wherever it sits", {
  # reticulate puts it in different places depending on the session.
  expect_equal(
    tabpfn:::clean_python_message(
      "X.Error: Too many rows.\nRun `reticulate::py_last_error()` for details."
    ),
    "Too many rows."
  )
  expect_equal(
    tabpfn:::clean_python_message(
      paste(
        "X.Error: Too many rows.",
        "Run `reticulate::py_last_error()` for details.",
        "And more."
      )
    ),
    "Too many rows. And more."
  )
})

test_that("clean_python_message keeps a line that ends in a URL", {
  # Nothing but the newline separates this from the line after it, so dropping
  # by sentence alone would take the advice about a GPU with it.
  msg <- paste0(
    "RuntimeError: Running on CPU with more than 5000 samples is not allowed.\n",
    "To override this behavior, set ignore_pretraining_limits=True.\n",
    "Alternatively, consider a GPU or https://github.com/PriorLabs/tabpfn-client"
  )

  out <- tabpfn:::clean_python_message(msg)
  expect_match(out, "Alternatively", fixed = TRUE)
  expect_no_match(out, "ignore_pretraining_limits", fixed = TRUE)
})

test_that("python_fit_hints picks advice by what failed", {
  expect_match(
    tabpfn:::python_fit_hints("Running on CPU with more than 5000 samples"),
    "TABPFN_ALLOW_CPU_LARGE_DATASET"
  )
  expect_match(
    tabpfn:::python_fit_hints("maximum number of samples"),
    "training_set_limit"
  )
  # Sampling rows cannot help with too many columns, so it is not offered.
  expect_no_match(
    tabpfn:::python_fit_hints("maximum number of features"),
    "training_set_limit"
  )
  expect_match(
    tabpfn:::python_fit_hints("maximum number of classes"),
    "version"
  )
})

test_that("an unrecognised failure gets no advice", {
  expect_length(tabpfn:::python_fit_hints("Something new and unmatched."), 0)
})

test_that("a real limit failure is rendered by us, not by reticulate", {
  skip_if_not_installing()
  skip_if_no_tabpfn()

  set.seed(1)
  n <- 50001
  d <- data.frame(y = rnorm(n), x1 = rnorm(n), x2 = rnorm(n))

  cnd <- tryCatch(
    tab_pfn(d[, 2:3], d$y, version = "v2.5"),
    error = function(cnd) cnd
  )
  msg <- conditionMessage(cnd)

  # Nothing here pins the library's wording, so a rewording upstream will not
  # fail this. What it checks is the plumbing we remove and the advice we add.
  expect_no_match(msg, "py_last_error", fixed = TRUE)
  expect_no_match(msg, "py_call_impl", fixed = TRUE)
  expect_no_match(msg, "TabPFNValidationError", fixed = TRUE)
  expect_no_match(msg, "ignore_pretraining_limits=True", fixed = TRUE)

  expect_match(msg, "training_set_limit", fixed = TRUE)
  expect_match(
    msg,
    "control_tab_pfn(ignore_pretraining_limits = TRUE)",
    fixed = TRUE
  )

  expect_equal(conditionCall(cnd), quote(tab_pfn()))
})
