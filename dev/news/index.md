# Changelog

## tabpfn (development version)

- [`control_tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/control_tab_pfn.md)
  now accepts `...` to pass additional arguments directly to the TabPFN
  Python constructor (e.g. `model_path`).

- [`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
  gains a `version` argument to select a specific TabPFN model version
  (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library’s current
  default is used
  ([\#15](https://github.com/tidymodels/tabpfn/issues/15)).

- New
  [`list_tabpfn_versions()`](https://tabpfn.tidymodels.org/dev/reference/list_tabpfn_versions.md)
  returns the model versions supported by the currently installed Python
  `tabpfn` library.

- Added `download_all_models` to close
  ([\#15](https://github.com/tidymodels/tabpfn/issues/15))
  [@frankiethull](https://github.com/frankiethull)

## tabpfn 0.1.0

CRAN release: 2026-03-18

- Initial version
