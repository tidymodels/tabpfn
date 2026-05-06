# tabpfn (development version)

- `control_tab_pfn()` now accepts `...` to pass additional arguments directly to
  the TabPFN Python constructor (e.g. `model_path`).

- `tab_pfn()` gains a `version` argument to select a specific TabPFN model
  version (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library's current
  default is used (#15).

- New `list_tabpfn_versions()` returns the model versions supported by the
  currently installed Python `tabpfn` library.

- Added `download_all_models` to close (#15) @frankiethull

# tabpfn 0.1.0

- Initial version



