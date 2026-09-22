# crop_training_set says what it dropped

    Code
      out <- tabpfn:::crop_training_set(molded, training_set_limit = 10, options = control_tab_pfn(
        device = "cuda"), version = "v3.5")
    Message
      ! Training on 10 of 32 rows.
      i TabPFN v3.5 supports up to 1,000,000 rows.
      i Set `training_set_limit` higher, or to `Inf`, to use all of the data.

# crop_training_set crops to the CPU limit and explains it

    Code
      out <- tabpfn:::crop_training_set(molded, training_set_limit = 10000, options = control_tab_pfn(
        device = "cpu"), version = "v3.5")
    Message
      ! Training on 5,000 of 5,001 rows.
      i TabPFN v3.5 is limited to 5,000 rows on a CPU. Its own limit is 1,000,000.
      i Set `training_set_limit = Inf` and `control_tab_pfn(ignore_pretraining_limits = TRUE)` to use all of the data.
      i The `TABPFN_ALLOW_CPU_LARGE_DATASET` environment variable lifts the CPU limit too.
      i A CPU fit that size will be slow.

