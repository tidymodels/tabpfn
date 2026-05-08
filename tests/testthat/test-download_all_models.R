test_that("download_all_models runs without error", {
  skip_if_no_tabpfn()

  expect_no_error(download_all_models())
})
