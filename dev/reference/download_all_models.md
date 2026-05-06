# download all TabPFN pre-trained model checkpoints

As of 2026-05-05, there are 36 pre-trained models equalling roughly 1.2
GB of storage. Each model is trained on various synthetic & real
datasets tailored to classification & regression. This function routine
will require you to sign a one-time license for both 2.5 & 2.6 model
varieties. Downloading all models will take some time, please be
patient!

## Usage

``` r
download_all_models(cache_dir = NULL)
```

## Arguments

- cache_dir:

  an option to override the default cache directory

## Examples

``` r
# \donttest{
download_all_models()
# }
```
