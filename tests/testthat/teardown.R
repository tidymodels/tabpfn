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

# Also clean up the test-specific temp cache
temp_cache <- file.path(tempdir(), "torchinductor_test")
if (dir.exists(temp_cache)) {
  unlink(temp_cache, recursive = TRUE, force = TRUE)
}
