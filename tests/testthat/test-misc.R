test_that("check_model_version validates correctly", {
  skip_if_no_tabpfn()

  expect_no_error(check_model_version("v2"))
  expect_no_error(check_model_version("v2.5"))
  expect_error(check_model_version("V2"), "not a valid model version")
  expect_error(check_model_version("invalid"), "not a valid model version")
})

test_that("normalize_model_version prefixes 'v' as needed", {
  # Already prefixed strings are left untouched
  expect_equal(normalize_model_version("v2"), "v2")
  expect_equal(normalize_model_version("v2.5"), "v2.5")

  # Bare strings get a 'v' prefix
  expect_equal(normalize_model_version("2"), "v2")
  expect_equal(normalize_model_version("2.5"), "v2.5")

  # Numeric input is coerced then prefixed
  expect_equal(normalize_model_version(2), "v2")
  expect_equal(normalize_model_version(2.5), "v2.5")

  # NULL passes through unchanged
  expect_null(normalize_model_version(NULL))
})

test_that("normalized numeric and string versions validate correctly", {
  skip_if_no_tabpfn()

  expect_no_error(check_model_version(normalize_model_version(2.5)))
  expect_no_error(check_model_version(normalize_model_version("2.5")))
  expect_no_error(check_model_version(normalize_model_version("v2.5")))
})

test_that("msg_tabpfn_not_available returns correct structure", {
  msg <- tabpfn:::msg_tabpfn_not_available()
  expect_named(msg, c("x", "i", "i"))
})

test_that("uses_canonical_env matches the resolved virtualenv", {
  local_mocked_bindings(
    py_exe = function(...) "/home/user/.virtualenvs/r-tabpfn/bin/python",
    virtualenv_exists = function(...) TRUE,
    virtualenv_python = function(...) {
      "/home/user/.virtualenvs/r-tabpfn/bin/python"
    },
    conda_python = function(...) stop("no conda"),
    .package = "reticulate"
  )

  expect_true(uses_canonical_env())
})

test_that("uses_canonical_env matches the resolved conda env", {
  local_mocked_bindings(
    py_exe = function(...) "/opt/conda/envs/r-tabpfn/bin/python",
    virtualenv_exists = function(...) FALSE,
    virtualenv_python = function(...) {
      "/home/user/.virtualenvs/r-tabpfn/bin/python"
    },
    conda_python = function(...) "/opt/conda/envs/r-tabpfn/bin/python",
    .package = "reticulate"
  )

  expect_true(uses_canonical_env())
})

test_that("uses_canonical_env is FALSE for a different env", {
  local_mocked_bindings(
    py_exe = function(...) "/usr/bin/python3",
    virtualenv_exists = function(...) TRUE,
    virtualenv_python = function(...) {
      "/home/user/.virtualenvs/r-tabpfn/bin/python"
    },
    conda_python = function(...) stop("no conda"),
    .package = "reticulate"
  )

  expect_false(uses_canonical_env())
})

test_that("uses_canonical_env is FALSE when Python is unresolved", {
  local_mocked_bindings(
    py_exe = function(...) stop("not initialized"),
    .package = "reticulate"
  )

  expect_false(uses_canonical_env())
})

test_that("the limits table matches the installed library", {
  # Ground truth lives in the checkpoints, so this needs a token and downloads
  # a model per version. Gated for the same reason the install tests are.
  skip_if_not_installing()
  skip_if_no_tabpfn()

  # Fit a classifier, not a regressor: a regression checkpoint carries no class
  # limit, and some versions report `MAX_NUMBER_OF_CLASSES` as 0 there.
  y <- factor(mtcars$am)

  for (v in tabpfn:::tabpfn_limits$version) {
    ours <- tabpfn:::tabpfn_limits_for(v)
    fit <- tab_pfn(mtcars[, -1], y, version = v)
    theirs <- fit$fit$inference_config_

    expect_equal(ours$rows_gpu, theirs$MAX_NUMBER_OF_SAMPLES, info = v)
    expect_equal(ours$rows_cpu, theirs$MAX_CPU_SAMPLES, info = v)
    expect_equal(ours$predictors, theirs$MAX_NUMBER_OF_FEATURES, info = v)
    expect_equal(ours$classes, theirs$MAX_NUMBER_OF_CLASSES, info = v)
  }
})

test_that("every version the library offers is in the limits table", {
  skip_if_no_tabpfn()

  # A new model version that we do not know about is approved by default, which
  # is safe but means no fast local check. This fails when it is time to add a
  # row; see the comment above `tabpfn_limits`.
  expect_setequal(tabpfn:::tabpfn_limits$version, tabpfn_list_versions())
})
