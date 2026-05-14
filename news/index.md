# Changelog

## tabpfn 0.2.0

- Updated notes on License Requirements in
  [`?tab_pfn`](https://tabpfn.tidymodels.org/reference/tab_pfn.md).

- [`control_tab_pfn()`](https://tabpfn.tidymodels.org/reference/control_tab_pfn.md)
  now accepts `...` to pass additional arguments directly to the TabPFN
  Python constructor (e.g. `model_path`).

- [`tab_pfn()`](https://tabpfn.tidymodels.org/reference/tab_pfn.md)
  gains a `version` argument to select a specific TabPFN model version
  (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library’s current
  default is used
  ([\#15](https://github.com/tidymodels/tabpfn/issues/15)).

- New
  [`tabpfn_list_versions()`](https://tabpfn.tidymodels.org/reference/tabpfn_list_versions.md)
  returns the model versions supported by the currently installed Python
  `tabpfn` library.

- Added
  [`tabpfn_download_models()`](https://tabpfn.tidymodels.org/reference/tabpfn_download_models.md)
  to close ([\#15](https://github.com/tidymodels/tabpfn/issues/15))
  [@frankiethull](https://github.com/frankiethull)

## tabpfn 0.1.0

CRAN release: 2026-03-18

- Initial version
