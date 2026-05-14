# Download all TabPFN pre-trained model checkpoints

As of 2026-05-05, there are 36 pre-trained models equaling roughly 1.2
GB of storage. Each model is trained on various synthetic & real
datasets tailored to classification & regression. This function routine
will require you to sign a one-time license for both 2.5 & 2.6 model
varieties. Downloading all models will take some time.

## Usage

``` r
tabpfn_download_models(cache_dir = NULL)
```

## Arguments

- cache_dir:

  an option to override the default cache directory

## Value

Invisibly returns `NULL`. Called for its side effect of downloading
model files.

## Examples

``` r
# \donttest{
tabpfn_download_models()
# }
```
