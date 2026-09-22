# tabpfn (development version)

- Data limits are now taken from the model version in use, rather than one fixed set of numbers applied to every version. A v3.5 model accepts up to 1,000,000 rows, 20,000 predictors and 160 classes; previously it was held to v2.5's limits and, for example, refused an outcome with more than 10 classes.

- `tab_pfn()` now reports when it samples the training set down to `training_set_limit`, which it previously did in silence.

- `tab_pfn()` no longer errors when the training set has too many rows. Row counts are now handled by sampling the data down to whatever the chosen model and device support, with a message saying so, rather than by refusing to fit. Too many predictors or classes still raises an error, as before.

- On a CPU, `tab_pfn()` samples down to the much lower limit the Python library enforces there (5,000 rows for v3.x, 1,000 for v2.x) and says so, instead of letting the fit fail with a Python error. `control_tab_pfn(ignore_pretraining_limits = TRUE)` or the `TABPFN_ALLOW_CPU_LARGE_DATASET` environment variable lifts it.

- Updated the `?tab_pfn` documentation: current model versions in the `version` examples, and a table of data limits per version that is generated from the same numbers the checks use.

# tabpfn 0.3.0

- Added quantile regression support to `predict()`.

- `tab_pfn()`'s `version` argument now accepts bare version numbers in addition to `"v"`-prefixed strings. A `"v"` is prepended automatically, so `version = 2.5`, `version = "2.5"`, and `version = "v2.5"` are all equivalent.

- New `tabpfn_initialize()` eagerly loads the Python `tabpfn` library (and PyTorch). Call it right after `library(tabpfn)` and before other OpenMP-using packages to avoid the segmentation fault described in #34.

- When the `"r-tabpfn"` environment (created by `install_tabpfn()`) is the Python installation reticulate resolves to, the `tabpfn` Python library is now imported eagerly at load time so that PyTorch claims OpenMP before other packages can, avoiding a segmentation fault (#34).

- New `install_tabpfn()` sets up a persistent `"r-tabpfn"` Python virtual environment. It has a `version` argument to pin a specific `tabpfn` release and, by default, offers to upgrade an existing environment when a newer release is available.

- Added a `type` argument to be consistent with parsnip. Defaults to `NULL`, which will produce all prediction types. 

- The fitted `tab_pfn` object now records: 

 - The underlying TabPFN model version in a `version` element, which is also shown by the print method. It falls back to `"unknown"` if the version cannot be determined.
 - The device(s) used to fit the model (e.g. `"cpu"`, `"mps"`, or `"cuda:0"`) in a `device` element, which is also shown by the print method. It falls back to `"unknown"` if the device cannot be determined.

# tabpfn 0.2.0

- Updated notes on License Requirements in `?tab_pfn`. 

- `control_tab_pfn()` now accepts `...` to pass additional arguments directly to the TabPFN Python constructor (e.g. `model_path`).

- `tab_pfn()` gains a `version` argument to select a specific TabPFN model version (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library's current
  default is used (#15).

- New `tabpfn_list_versions()` returns the model versions supported by the currently installed Python `tabpfn` library.

- Added `tabpfn_download_models()` to close (#15) @frankiethull

# tabpfn 0.1.0

- Initial version



