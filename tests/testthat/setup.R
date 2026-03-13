# Ensure PyTorch cache goes to temp directory during tests
# This is redundant with .onLoad() but provides extra safety for tests
if (Sys.getenv("TORCHINDUCTOR_CACHE_DIR") == "") {
  torch_cache_dir <- file.path(tempdir(), "torchinductor_test")
  Sys.setenv(TORCHINDUCTOR_CACHE_DIR = torch_cache_dir)
}
