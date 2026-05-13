test_that("tabpfn_download_models runs without error", {
  skip_if_no_tabpfn()

  expect_no_error(tabpfn_download_models())
})
