#' download all TabPFN pre-trained model checkpoints 
#'
#' @description 
#' As of 2026-05-05, there are 36 pre-trained models equalling roughly 1.2 GB of storage.
#' Each model is trained on various synthetic & real datasets tailored to classification & regression. 
#' This function routine will require you to sign a one-time license for both 2.5 & 2.6 model varieties. 
#' Downloading all models will take some time, please be patient!
#' 
#' @param cache_dir an option to override the default cache directory
#'
#' @returns 
#'
#' @export
#' @examples 
#' \donttest{
#' download_all_models()
#' }
download_all_models <- function(cache_dir = NULL){
pathlib <- reticulate::import("pathlib")
tabpfn <- reticulate::import("tabpfn")
 model_loading <- tabpfn$model_loading

  if(is.null(cache_dir)) {
  cache_dir <- model_loading$get_cache_dir() # This is the key part, it extracts TabPFN's expected cache dir
} else {
    cache_dir <- pathlib$Path(path.expand(cache_dir))
  }
  model_loading$download_all_models(to = cache_dir)

}
