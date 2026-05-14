# List available TabPFN model versions

Returns a character vector of valid model version strings accepted by
[`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)'s
`version` argument. The available model versions are queried directly
from the currently installed Python `tabpfn` library, not hard-coded in
this package, so results may differ across Python library versions.

## Usage

``` r
tabpfn_list_versions()
```

## Value

A character vector of model version strings.
