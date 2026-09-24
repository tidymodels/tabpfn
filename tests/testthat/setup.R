# .onLoad() points TORCHINDUCTOR_CACHE_DIR and SKB_DATA_DIRECTORY at
# persistent cache dirs (tools::R_user_dir()), and both will already be set
# by the time this file runs, so these must unconditionally override them
# rather than only fill them in when unset -- otherwise tests would read
# from and write into the real user cache.
Sys.setenv(TORCHINDUCTOR_CACHE_DIR = file.path(tempdir(), "torchinductor_test"))
Sys.setenv(SKB_DATA_DIRECTORY = file.path(tempdir(), "skrub_data_test"))
