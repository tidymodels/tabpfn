# Clean up any torchinductor directories after tests complete
torch_dirs <- list.files(
  path = getwd(),
  pattern = "^torchinductor",
  full.names = TRUE,
  recursive = FALSE,
  include.dirs = TRUE
)

for (dir in torch_dirs) {
  if (dir.exists(dir)) {
    unlink(dir, recursive = TRUE, force = TRUE)
  }
}

# Also clean up the test-specific temp caches
pkg_cache_dirnames <-
  c("torchinductor_test", "skrub_data_test")
unlink(
  file.path(tempdir(), pkg_cache_dirnames),
  recursive = TRUE,
  force = TRUE
)
