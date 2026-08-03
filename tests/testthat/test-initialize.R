test_that("tabpfn_initialize forces the import and returns NULL invisibly", {
  called <- FALSE
  local_mocked_bindings(
    tabpfn_list_versions = function() {
      called <<- TRUE
      "v2"
    }
  )

  expect_invisible(res <- tabpfn_initialize())
  expect_null(res)
  expect_true(called)
})

test_that("tabpfn_initialize errors when tabpfn is not installed", {
  local_mocked_bindings(is_tab_pfn_installed = function() FALSE)
  expect_error(tabpfn_initialize(), "not installed")
})

test_that("tabpfn_initialize loads the Python library without error", {
  skip_if_no_tabpfn()

  expect_no_error(tabpfn_initialize())
})
