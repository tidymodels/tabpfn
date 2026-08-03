# Eagerly initialize the TabPFN Python library

Forces the Python `tabpfn` library (and its PyTorch dependency) to load
now instead of on first use. Because PyTorch bundles its own OpenMP
runtime, loading it before any other package that uses OpenMP avoids the
segmentation fault described in
<https://github.com/tidymodels/tabpfn/issues/34>.

For this to work, call it as the very first thing in your session, using
`tabpfn::tabpfn_initialize()` (with the `::` prefix so it runs before
[`library(tabpfn)`](https://tabpfn.tidymodels.org) and before any other
package that might load OpenMP, such as recipes):

    tabpfn::tabpfn_initialize()
    library(tabpfn)
    suppressPackageStartupMessages(library(recipes))
    fit_obj <- tab_pfn(mpg ~ ., data = mtcars)

## Usage

``` r
tabpfn_initialize()
```

## Value

`NULL`, invisibly. Called for its side effect of loading the Python
library.

## Examples

``` r
if (FALSE) { # \dontrun{
tabpfn::tabpfn_initialize()
library(tabpfn)
} # }
```
