# tabpfn (development version)

- `tab_pfn()` gains a `version` argument to select a specific TabPFN model
  version (e.g., `"v2"`, `"v2.5"`). When `NULL`, the Python library's current
  default is used (#15).

- New `download_tab_pfn_models()` downloads all available model weights to the
  local cache. Already-cached weights are skipped.

# tabpfn 0.1.0

- Initial version



