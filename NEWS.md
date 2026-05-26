# tabpfn (development version)

- Added a `type` argument to be consistent with parsnip. Defaults to `NULL`, which will produce all prediction types. 

# tabpfn 0.2.0

- Updated notes on License Requirements in `?tab_pfn`. 

- `control_tab_pfn()` now accepts `...` to pass additional arguments directly to the TabPFN Python constructor (e.g. `model_path`).

- `tab_pfn()` gains a `version` argument to select a specific TabPFN model version (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library's current
  default is used (#15).

- New `tabpfn_list_versions()` returns the model versions supported by the currently installed Python `tabpfn` library.

- Added `tabpfn_download_models()` to close (#15) @frankiethull

# tabpfn 0.1.0

- Initial version



