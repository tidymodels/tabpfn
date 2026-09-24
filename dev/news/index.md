# Changelog

## tabpfn (development version)

- The `training_set_limit` argument of
  [`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
  now defaults to `Inf`, so all of your data is used. It previously
  sampled anything larger down to 10,000 rows without saying so.

- [`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
  no longer checks your data against the model’s limits; the Python
  library does, and its error names the model in use. Limits now follow
  the version you chose rather than one fixed set.

- Fixed a failure that stopped models from fitting at all on some
  setups, reported as
  `AttributeError: property 'stream' of '_StderrHandler' object has no setter`
  ([\#40](https://github.com/tidymodels/tabpfn/issues/40)). The package
  no longer uses
  [`reticulate::py_capture_output()`](https://rstudio.github.io/reticulate/reference/py_capture_output.html),
  which reassigns the streams of Python’s logging handlers and errors
  when one of them is read-only.

- Failures coming from the Python library are now reported as R errors.
  The message keeps what the library said and drops the wrapper around
  it, and
  [`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
  adds what to do about it in R, such as lowering `training_set_limit`.
  This covers [`predict()`](https://rdrr.io/r/stats/predict.html) as
  well.

- [`?tab_pfn`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
  now lists each model version’s limits, including the lower one that
  applies on a CPU, and its examples use current versions rather than
  earlier ones.

- Test snapshots now record TabPFN v3.5, the model the Python library
  currently defaults to. They will need updating again whenever that
  default moves.

- CI pins `torch` to 2.13.0. The 2.14.0 release triggers the
  `_StderrHandler` failure above, and the pin stays until that is
  settled upstream.

## tabpfn 0.3.0

CRAN release: 2026-09-01

- Added quantile regression support to
  [`predict()`](https://rdrr.io/r/stats/predict.html).

- [`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)’s
  `version` argument now accepts bare version numbers in addition to
  `"v"`-prefixed strings. A `"v"` is prepended automatically, so
  `version = 2.5`, `version = "2.5"`, and `version = "v2.5"` are all
  equivalent.

- New
  [`tabpfn_initialize()`](https://tabpfn.tidymodels.org/dev/reference/tabpfn_initialize.md)
  eagerly loads the Python `tabpfn` library (and PyTorch). Call it right
  after [`library(tabpfn)`](https://tabpfn.tidymodels.org) and before
  other OpenMP-using packages to avoid the segmentation fault described
  in [\#34](https://github.com/tidymodels/tabpfn/issues/34).

- When the `"r-tabpfn"` environment (created by
  [`install_tabpfn()`](https://tabpfn.tidymodels.org/dev/reference/install_tabpfn.md))
  is the Python installation reticulate resolves to, the `tabpfn` Python
  library is now imported eagerly at load time so that PyTorch claims
  OpenMP before other packages can, avoiding a segmentation fault
  ([\#34](https://github.com/tidymodels/tabpfn/issues/34)).

- New
  [`install_tabpfn()`](https://tabpfn.tidymodels.org/dev/reference/install_tabpfn.md)
  sets up a persistent `"r-tabpfn"` Python virtual environment. It has a
  `version` argument to pin a specific `tabpfn` release and, by default,
  offers to upgrade an existing environment when a newer release is
  available.

- Added a `type` argument to be consistent with parsnip. Defaults to
  `NULL`, which will produce all prediction types.

- The fitted `tab_pfn` object now records:

- The underlying TabPFN model version in a `version` element, which is
  also shown by the print method. It falls back to `"unknown"` if the
  version cannot be determined.

- The device(s) used to fit the model (e.g. `"cpu"`, `"mps"`, or
  `"cuda:0"`) in a `device` element, which is also shown by the print
  method. It falls back to `"unknown"` if the device cannot be
  determined.

## tabpfn 0.2.0

CRAN release: 2026-05-14

- Updated notes on License Requirements in
  [`?tab_pfn`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md).

- [`control_tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/control_tab_pfn.md)
  now accepts `...` to pass additional arguments directly to the TabPFN
  Python constructor (e.g. `model_path`).

- [`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
  gains a `version` argument to select a specific TabPFN model version
  (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library’s current
  default is used
  ([\#15](https://github.com/tidymodels/tabpfn/issues/15)).

- New
  [`tabpfn_list_versions()`](https://tabpfn.tidymodels.org/dev/reference/tabpfn_list_versions.md)
  returns the model versions supported by the currently installed Python
  `tabpfn` library.

- Added
  [`tabpfn_download_models()`](https://tabpfn.tidymodels.org/dev/reference/tabpfn_download_models.md)
  to close ([\#15](https://github.com/tidymodels/tabpfn/issues/15))
  [@frankiethull](https://github.com/frankiethull)

## tabpfn 0.1.0

CRAN release: 2026-03-18

- Initial version
