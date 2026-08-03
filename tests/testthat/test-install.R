# resolve_tabpfn_spec() is pure (no Python, no network), so it runs everywhere.

test_that("resolve_tabpfn_spec() maps versions to pip specifications", {
  expect_equal(resolve_tabpfn_spec("default"), "tabpfn")
  expect_equal(resolve_tabpfn_spec("release"), "tabpfn")
  expect_equal(resolve_tabpfn_spec(NULL), "tabpfn")

  expect_equal(resolve_tabpfn_spec("2.0.9"), "tabpfn==2.0.9")

  # Pip specifications pass through, with or without the package name.
  expect_equal(resolve_tabpfn_spec(">=2.0"), "tabpfn>=2.0")
  expect_equal(resolve_tabpfn_spec("tabpfn==2.0.9"), "tabpfn==2.0.9")
})

test_that("version comparison is numeric, not lexicographic", {
  # The string-compare trap: "2.0.10" < "2.0.9" as text, but not as versions.
  expect_true(numeric_version("2.0.10") > numeric_version("2.0.9"))
})

# ------------------------------------------------------------------------------
# A real install into a throwaway environment. Opt-in only.

test_that("install_tabpfn() creates an environment with a pinned version", {
  skip_if_not_installing()

  envname <- paste0("r-tabpfn-test-", as.integer(runif(1, 1, 1e6)))
  withr::defer(
    try(reticulate::virtualenv_remove(envname, confirm = FALSE), silent = TRUE)
  )

  install_tabpfn(
    version = "2.0.9",
    envname = envname,
    new_env = TRUE,
    restart_session = FALSE
  )

  expect_true(env_exists(envname))
  expect_equal(env_tabpfn_version(envname), "2.0.9")
})
