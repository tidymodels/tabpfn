test_that("check_model_version validates correctly", {
  skip_if_no_tabpfn()

  expect_no_error(check_model_version("v2"))
  expect_no_error(check_model_version("v2.5"))
  expect_error(check_model_version("V2"), "not a valid model version")
  expect_error(check_model_version("invalid"), "not a valid model version")
})

test_that("msg_tabpfn_not_available returns correct structure", {
  msg <- tabpfn:::msg_tabpfn_not_available()
  expect_named(msg, c("x", "i", "i"))
})
