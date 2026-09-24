# Install the TabPFN Python environment

Sets up a persistent Python virtual environment containing the `tabpfn`
Python library so that
[`tab_pfn()`](https://tabpfn.tidymodels.org/dev/reference/tab_pfn.md)
and friends can use it. By default the environment is named
`"r-tabpfn"`, which reticulate automatically discovers and prefers over
an ephemeral environment (see the *Environment discovery* section).

## Usage

``` r
install_tabpfn(
  version = "default",
  envname = "r-tabpfn",
  check_latest = TRUE,
  extra_packages = NULL,
  python_version = NULL,
  method = c("auto", "virtualenv", "conda"),
  new_env = identical(envname, "r-tabpfn"),
  restart_session = TRUE,
  ...
)
```

## Arguments

- version:

  The `tabpfn` version to install. Use `"default"` (or `NULL`) to
  install the latest release, a bare version string such as `"2.0.9"` to
  pin an exact version, or a full pip specification such as `">=2.0"`.

- envname:

  The name of the Python virtual environment to create or use. The
  default, `"r-tabpfn"`, is auto-discovered by reticulate.

- check_latest:

  A logical. When `TRUE` (the default) and no explicit `version` is
  given, an existing environment is compared against the latest release
  on PyPI and you are asked whether to upgrade. Set to `FALSE` to skip
  this check (useful when intentionally staying on an older version).

- extra_packages:

  An optional character vector of additional Python packages to install
  alongside `tabpfn`. You can also use it to set the version of one of
  `tabpfn`'s own dependencies, such as holding `torch` at an older
  release. See the *Pinning dependencies* section.

- python_version:

  An optional Python version to use for the environment.

- method:

  The installation method, passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

- new_env:

  A logical. When `TRUE`, an existing environment named `envname` is
  removed and rebuilt from scratch. Defaults to `TRUE` only for the
  canonical `"r-tabpfn"` environment.

- restart_session:

  A logical. When `TRUE` (the default) and running in RStudio, the R
  session is restarted after installation so the new environment takes
  effect.

- ...:

  Additional arguments passed to
  [`reticulate::py_install()`](https://rstudio.github.io/reticulate/reference/py_install.html).

## Value

Invisibly returns the environment name.

## Environment discovery

Because the package calls `reticulate::import("tabpfn")`, reticulate
will automatically use a virtual environment named `"r-tabpfn"` if one
exists, preferring it over the ephemeral environment that is otherwise
created on demand. Environments selected via `RETICULATE_PYTHON`,
`VIRTUAL_ENV`, or a project-local `.venv` take precedence over
`"r-tabpfn"`.

## Pinning dependencies

The Python `tabpfn` library pulls in other Python packages, among them
`torch`, `numpy`, `pandas`, and `scikit-learn`. A new release of any one
of them can break code that worked the week before, even though your R
version and your `tabpfn` version did not change. The error usually
points at `tabpfn` rather than at the package that changed, so pinning
the suspect dependency is a quick way to confirm the cause and to keep
working until a fix lands upstream.

To pin a dependency in the persistent environment that
`install_tabpfn()` builds, pass it and the version you want in
`extra_packages`:


      install_tabpfn(
        version = "2.0.9",
        extra_packages = "torch==2.13.0",
        new_env = TRUE
      )

`extra_packages` is used only when an install runs. If `envname` already
exists and already has the version you asked for, this function returns
early and ignores the pin. Pass `new_env = TRUE` to delete the
environment and build it again with the pin.

To pin a dependency in the ephemeral environment instead, call
[`reticulate::py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html)
before you fit a model:


      library(tabpfn)
      reticulate::py_require("torch==2.13.0")

## Examples

``` r
if (FALSE) { # \dontrun{
# Install the latest release into "r-tabpfn"
install_tabpfn()

# Pin a specific version
install_tabpfn(version = "2.0.9")

# Pin a dependency as well
install_tabpfn(version = "2.0.9", extra_packages = "torch==2.13.0")
} # }
```
