#' List available TabPFN model versions
#'
#' Returns a character vector of valid model version strings accepted by
#' [tab_pfn()]'s `version` argument. The available model versions are queried
#' directly from the currently installed Python `tabpfn` library, not
#' hard-coded in this package, so results may differ across Python library
#' versions.
#' @return A character vector of model version strings.
#' @export
tabpfn_list_versions <- function() {
  if (!is_tab_pfn_installed()) {
    cli::cli_abort(msg_tabpfn_not_available())
  }

  tabpfn <- import_tabpfn()
  builtins <- reticulate::import_builtins()
  tabpfn$constants$ModelVersion |>
    builtins$list() |>
    unlist()
}

#' Download all TabPFN pre-trained model checkpoints
#'
#' @description
#' As of 2026-05-05, there are 36 pre-trained models equaling roughly 1.2 GB
#' of storage. Each model is trained on various synthetic & real datasets
#' tailored to classification & regression. This function routine will require
#' you to sign a one-time license for both 2.5 & 2.6 model varieties.
#' Downloading all models will take some time.
#'
#' @param cache_dir an option to override the default cache directory
#'
#' @returns Invisibly returns `NULL`. Called for its side effect of
#' downloading model files.
#'
#' @export
#' @examples
#' \donttest{
#' tabpfn_download_models()
#' }
tabpfn_download_models <- function(cache_dir = NULL) {
  pathlib <- reticulate::import("pathlib")
  tabpfn <- import_tabpfn()
  model_loading <- tabpfn$model_loading
  if (is.null(cache_dir)) {
    cache_dir <- model_loading$get_cache_dir()
  } else {
    cache_dir <- pathlib$Path(path.expand(cache_dir))
  }
  model_loading$download_all_models(to = cache_dir)
  invisible()
}
