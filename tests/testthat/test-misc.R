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
