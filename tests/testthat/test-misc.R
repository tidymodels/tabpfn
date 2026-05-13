test_that("tabpfn_list_versions returns a character vector", {
  skip_if_no_tabpfn()

  versions <- tabpfn_list_versions()
  expect_type(versions, "character")
  expect_gt(length(versions), 0)
})

test_that("tabpfn_list_versions includes known versions", {
  skip_if_no_tabpfn()

  versions <- tabpfn_list_versions()
  expect_contains(versions, "v2")
})

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

test_that("tabpfn_list_versions errors when tabpfn not installed", {
  local_mocked_bindings(is_tab_pfn_installed = function() FALSE)
  expect_error(tabpfn_list_versions(), "not installed")
})
