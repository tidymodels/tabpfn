new_rf_pfn <- function(
  fit,
  levels,
  training,
  logging,
  tree_type,
  blueprint,
  call = NULL
) {
  check_character(levels, allow_null = TRUE)
  check_string(tree_type)

  hardhat::new_model(
    fit       = fit,
    levels    = levels,
    training  = training,
    logging   = logging,
    tree_type = tree_type,
    blueprint = blueprint,
    class     = "rf_pfn"
  )
}
