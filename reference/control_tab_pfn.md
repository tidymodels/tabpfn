# Controlling TabPFN execution

Controlling TabPFN execution

## Usage

``` r
control_tab_pfn(
  n_preprocessing_jobs = 1L,
  device = "auto",
  ignore_pretraining_limits = FALSE,
  inference_precision = "auto",
  fit_mode = "fit_preprocessors",
  memory_saving_mode = "auto",
  random_state = sample.int(10^6, 1),
  ...
)
```

## Arguments

- n_preprocessing_jobs:

  An integer for the number of worker processes. A value of -1L
  indicates all possible resources.

- device:

  A character value for the device used for torch (e.g., `"cpu"`,
  `"cuda"`, `"mps"`, etc.). Th default is `"auto"`.

- ignore_pretraining_limits:

  A logical to bypass the default data limits on:the number of training
  set samples (10,000) and, the number of predictors (500). There is an
  unchangeable limit to the number of classes (10).

- inference_precision:

  A character value for the trade off between speed and reproducibility.
  This can be a torch `dtype`, `"autocast"` (for torch's mixed-precision
  autocast), or "auto".

- fit_mode:

  A character value to control how the are preprocessed and/or cached.
  Values are `"fit_preprocessors"` (the default), `"low_memory"`,
  `"fit_with_cache"`, and `"batched"`.

- memory_saving_mode:

  A character string to help with out-of-memory errors. Values are
  either a logical or `"auto"`.

- random_state:

  An integer to set the random number stream.

- ...:

  Additional named arguments passed directly to the TabPFN Python
  constructor. Use this to supply options not covered by the named
  parameters above (e.g. arguments added in newer versions of the Python
  package).

## Value

A list with extra class `"control_tab_pfn"` that has named elements for
each of the argument values.

## References

<https://github.com/PriorLabs/TabPFN/blob/main/src/tabpfn/classifier.py>,
<https://github.com/PriorLabs/TabPFN/blob/main/src/tabpfn/regressor.py>

## Examples

``` r
control_tab_pfn()
#> control object for `tab_pfn()`
#> 
#> non-default arguments:
#> • `random_state`: 841111
```
