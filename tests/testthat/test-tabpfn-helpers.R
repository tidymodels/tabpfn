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

test_that("tabpfn_list_versions errors when tabpfn not installed", {
  local_mocked_bindings(is_tab_pfn_installed = function() FALSE)
  expect_error(tabpfn_list_versions(), "not installed")
})

test_that("tabpfn_download_models runs without error", {
  skip_if_no_tabpfn()

  expect_no_error(tabpfn_download_models())
})
