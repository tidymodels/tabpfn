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

test_that("check_data_constraints does not police rows", {
  x <- matrix(0, nrow = 50001, ncol = 2)
  y <- factor(rep(c("a", "b"), length.out = 50001))

  # Rows are handled by cropping before this runs, so even a count well over
  # v2.5's limit passes here.
  expect_silent(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda"),
      version = "v2.5"
    )
  )
})

test_that("check_data_constraints approves an unknown version", {
  x <- matrix(0, nrow = 10, ncol = 2001)
  y <- factor(letters[1:11][rep(1:11, length.out = 10)])

  # Nothing is known about this version, so every check stands down and the
  # Python side is left to complain.
  expect_silent(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda"),
      version = "v9.9"
    )
  )
  expect_silent(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda"),
      version = NA_character_
    )
  )
})

test_that("check_data_constraints errors when too many columns", {
  x <- matrix(0, nrow = 10, ncol = 2001)
  y <- factor(rep(c("a", "b"), length.out = 10))
  expect_error(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda"),
      version = "v2.5"
    ),
    "2,000"
  )
})

test_that("check_data_constraints errors when too many classes", {
  x <- matrix(0, nrow = 11, ncol = 2)
  y <- factor(letters[1:11])
  expect_error(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda"),
      version = "v2.5"
    ),
    "classes"
  )
})

test_that("the class limit follows the version and ignores the bypass", {
  x <- matrix(0, nrow = 11, ncol = 2)
  y <- factor(letters[1:11])

  # 11 classes is over v2.5's limit of 10 but far under v3.5's 160.
  expect_silent(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda"),
      version = "v3.5"
    )
  )

  # `ignore_pretraining_limits` does not lift the class limit, matching
  # `validate_max_classes()` on the Python side.
  expect_error(
    tabpfn:::check_data_constraints(
      x,
      y,
      control_tab_pfn(device = "cuda", ignore_pretraining_limits = TRUE),
      version = "v2.5"
    ),
    "classes"
  )
})

test_that("limits lookup", {
  expect_equal(tabpfn:::tabpfn_limits_for("v3.5")$rows_cpu, 5000)
  expect_equal(tabpfn:::tabpfn_limits_for("v2")$predictors, 500)

  unknown <- tabpfn:::tabpfn_limits_for("nope")
  expect_true(all(is.na(unlist(unknown))))
  expect_true(all(is.na(unlist(tabpfn:::tabpfn_limits_for(NULL)))))
})

test_that("resolve_limit_version prefers the version, then falls back", {
  expect_equal(
    tabpfn:::resolve_limit_version(2.5, control_tab_pfn()),
    "v2.5"
  )
  expect_equal(
    tabpfn:::resolve_limit_version("v3", control_tab_pfn()),
    "v3"
  )

  # A checkpoint path means the version comes from that file, which we cannot
  # read, so nothing is known.
  expect_true(
    is.na(
      tabpfn:::resolve_limit_version(
        NULL,
        control_tab_pfn(model_path = "/tmp/some_model.ckpt")
      )
    )
  )
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

test_that("crop_training_set says what it dropped", {
  skip_if_no_tabpfn()
  molded <- hardhat::mold(mtcars[, -1], mtcars[, 1])

  expect_snapshot(
    out <- tabpfn:::crop_training_set(
      molded,
      training_set_limit = 10,
      options = control_tab_pfn(device = "cuda"),
      version = "v3.5"
    )
  )
  expect_equal(nrow(out$outcomes), 10)
})

test_that("crop_training_set is quiet when nothing is dropped", {
  skip_if_no_tabpfn()
  molded <- hardhat::mold(mtcars[, -1], mtcars[, 1])

  expect_silent(
    out <- tabpfn:::crop_training_set(
      molded,
      training_set_limit = 10000,
      options = control_tab_pfn(device = "cuda"),
      version = "v3.5"
    )
  )
  expect_equal(nrow(out$outcomes), nrow(mtcars))
})

test_that("crop_training_set crops to the CPU limit and explains it", {
  skip_if_no_tabpfn()
  set.seed(1)
  n <- 5001
  d <- data.frame(y = rnorm(n), x1 = rnorm(n), x2 = rnorm(n))
  molded <- hardhat::mold(d[, -1], d$y)

  # v3.5 takes 1M rows, but only 5,000 of them on a CPU.
  expect_snapshot(
    out <- tabpfn:::crop_training_set(
      molded,
      training_set_limit = 10000,
      options = control_tab_pfn(device = "cpu"),
      version = "v3.5"
    )
  )
  expect_equal(nrow(out$outcomes), 5000)
})

test_that("the bypass lifts the CPU crop", {
  skip_if_no_tabpfn()
  set.seed(1)
  n <- 5001
  d <- data.frame(y = rnorm(n), x1 = rnorm(n), x2 = rnorm(n))
  molded <- hardhat::mold(d[, -1], d$y)

  expect_silent(
    out <- tabpfn:::crop_training_set(
      molded,
      training_set_limit = Inf,
      options = control_tab_pfn(
        device = "cpu",
        ignore_pretraining_limits = TRUE
      ),
      version = "v3.5"
    )
  )
  expect_equal(nrow(out$outcomes), n)
})

test_that("the CPU limit applies even to training_set_limit = Inf", {
  skip_if_no_tabpfn()
  set.seed(1)
  n <- 5001
  d <- data.frame(y = rnorm(n), x1 = rnorm(n), x2 = rnorm(n))
  molded <- hardhat::mold(d[, -1], d$y)

  # `Inf` asks for all the data, but a CPU fit still stops at 5,000. Say so
  # rather than erroring; the message names the bypass that lifts it.
  expect_message(
    out <- tabpfn:::crop_training_set(
      molded,
      training_set_limit = Inf,
      options = control_tab_pfn(device = "cpu"),
      version = "v3.5"
    ),
    "limited to 5,000 rows on a CPU"
  )
  expect_equal(nrow(out$outcomes), 5000)
})

test_that("the device comes from the library, not from us", {
  skip_if_no_tabpfn()
  expect_false(tabpfn:::py_fit_on_cpu("cuda"))
  expect_true(tabpfn:::py_fit_on_cpu("cpu"))

  # "auto" has to honour TABPFN_EXCLUDE_DEVICES, which is why we ask the
  # library instead of asking torch ourselves.
  local_tabpfn_cpu()
  expect_true(tabpfn:::py_fit_on_cpu("auto"))
})

test_that("version = NULL resolves to the library default", {
  skip_if_no_tabpfn()
  resolved <- tabpfn:::resolve_limit_version(NULL, control_tab_pfn())
  expect_true(resolved %in% tabpfn_list_versions())
  expect_equal(resolved, tabpfn:::py_default_model_version())
})
