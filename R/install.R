#' Install the TabPFN Python environment
#'
#' @description
#' Sets up a persistent Python virtual environment containing the `tabpfn`
#' Python library so that [tab_pfn()] and friends can use it. By default the
#' environment is named `"r-tabpfn"`, which reticulate automatically discovers
#' and prefers over an ephemeral environment (see the *Environment discovery*
#' section).
#'
#' @param version The `tabpfn` version to install. Use `"default"` (or `NULL`)
#'   to install the latest release, a bare version string such as `"2.0.9"` to
#'   pin an exact version, or a full pip specification such as `">=2.0"`.
#' @param envname The name of the Python virtual environment to create or use.
#'   The default, `"r-tabpfn"`, is auto-discovered by reticulate.
#' @param check_latest A logical. When `TRUE` (the default) and no explicit
#'   `version` is given, an existing environment is compared against the latest
#'   release on PyPI and you are asked whether to upgrade. Set to `FALSE` to
#'   skip this check (useful when intentionally staying on an older version).
#' @param extra_packages An optional character vector of additional Python
#'   packages to install alongside `tabpfn`.
#' @param python_version An optional Python version to use for the environment.
#' @param method The installation method, passed to [reticulate::py_install()].
#' @param new_env A logical. When `TRUE`, an existing environment named
#'   `envname` is removed and rebuilt from scratch. Defaults to `TRUE` only for
#'   the canonical `"r-tabpfn"` environment.
#' @param restart_session A logical. When `TRUE` (the default) and running in
#'   RStudio, the R session is restarted after installation so the new
#'   environment takes effect.
#' @param ... Additional arguments passed to [reticulate::py_install()].
#'
#' @section Environment discovery:
#' Because the package calls `reticulate::import("tabpfn")`, reticulate will
#' automatically use a virtual environment named `"r-tabpfn"` if one exists,
#' preferring it over the ephemeral environment that is otherwise created on
#' demand. Environments selected via `RETICULATE_PYTHON`, `VIRTUAL_ENV`, or a
#' project-local `.venv` take precedence over `"r-tabpfn"`.
#'
#' @return Invisibly returns the environment name.
#' @examples
#' \dontrun{
#' # Install the latest release into "r-tabpfn"
#' install_tabpfn()
#'
#' # Pin a specific version
#' install_tabpfn(version = "2.0.9")
#' }
#' @export
install_tabpfn <- function(
  version = "default",
  envname = "r-tabpfn",
  check_latest = TRUE,
  extra_packages = NULL,
  python_version = NULL,
  method = c("auto", "virtualenv", "conda"),
  new_env = identical(envname, "r-tabpfn"),
  restart_session = TRUE,
  ...
) {
  check_string(version, allow_null = TRUE)
  check_string(envname)
  check_bool(check_latest)
  check_bool(new_env)
  check_bool(restart_session)
  method <- rlang::arg_match(method)

  explicit_version <- !(is.null(version) ||
    version %in% c("default", "release"))
  spec <- resolve_tabpfn_spec(version)
  exists <- env_exists(envname)

  # Can't safely modify an environment whose Python is already loaded.
  if (exists && py_is_initialized()) {
    cli::cli_abort(
      c(
        "x" = "Can't modify {.val {envname}} because Python is already loaded in
               this R session.",
        "i" = "Restart R, then run {.code install_tabpfn()} before using tabpfn
               functions."
      ),
      call = NULL
    )
  }

  # ---- Fresh install ---------------------------------------------------------
  if (!exists) {
    cli::cli_inform(c("i" = "Creating virtual environment {.val {envname}}."))
    install_env(spec, envname, method, python_version, extra_packages, ...)
    installed <- env_tabpfn_version(envname)
    cli::cli_inform(
      c("v" = "Installed {.pkg tabpfn} {installed} into {.val {envname}}.")
    )
    return(finish_install(envname, restart_session))
  }

  installed <- env_tabpfn_version(envname)

  # ---- Explicit version requested --------------------------------------------
  if (explicit_version) {
    target <- sub("^tabpfn==", "", spec)
    if (!is.null(installed) && identical(installed, target)) {
      cli::cli_inform(
        c(
          "v" = "{.val {envname}} already has {.pkg tabpfn} {installed}.
                 Nothing to do.",
          "i" = "Use {.code new_env = TRUE} to force a clean reinstall."
        )
      )
      return(invisible(envname))
    }

    if (new_env) {
      return(recreate_env(
        spec,
        envname,
        method,
        python_version,
        extra_packages,
        installed = installed,
        target = spec,
        restart_session,
        ...
      ))
    }

    install_env(spec, envname, method, python_version, extra_packages, ...)
    new_version <- env_tabpfn_version(envname)
    cli::cli_inform(
      c("v" = "Installed {.pkg tabpfn} {new_version} into {.val {envname}}.")
    )
    return(finish_install(envname, restart_session))
  }

  # ---- No explicit version ---------------------------------------------------
  if (!check_latest) {
    cli::cli_inform(
      c(
        "v" = "{.val {envname}} already exists; skipping version check
              ({.code check_latest = FALSE})."
      )
    )
    return(invisible(envname))
  }

  latest <- tryCatch(pypi_latest_version(), error = function(e) NULL)

  if (is.null(latest)) {
    cli::cli_inform(
      c(
        "!" = "Could not reach PyPI to check for the latest {.pkg tabpfn}
               version.",
        "i" = "Proceeding with the currently installed version ({installed})."
      )
    )
    return(invisible(envname))
  }

  if (
    !is.null(installed) &&
      numeric_version(installed) >= numeric_version(latest)
  ) {
    cli::cli_inform(
      c(
        "v" = "{.val {envname}} already has the latest {.pkg tabpfn}
              ({installed}). Nothing to do."
      )
    )
    return(invisible(envname))
  }

  cli::cli_inform(
    c(
      "i" = "{.val {envname}} has {.pkg tabpfn} {installed}. A newer version
            ({latest}) is available."
    )
  )

  upgrade <- rlang::is_interactive() &&
    tabpfn_confirm(paste0("Upgrade to ", latest, "? (Yes/no/cancel) "), TRUE)

  if (!upgrade) {
    cli::cli_inform(
      c(
        "i" = "Keeping {.pkg tabpfn} {installed}.",
        "i" = "To skip this check in the future, pass {.code check_latest = FALSE}."
      )
    )
    return(invisible(envname))
  }

  install_env(
    paste0("tabpfn==", latest),
    envname,
    method,
    python_version,
    extra_packages,
    ...
  )
  cli::cli_inform(
    c("v" = "Upgraded {.pkg tabpfn} to {latest} in {.val {envname}}.")
  )
  finish_install(envname, restart_session)
}

# ------------------------------------------------------------------------------
# Recreate an existing environment (destructive) after confirmation.

recreate_env <- function(
  spec,
  envname,
  method,
  python_version,
  extra_packages,
  installed,
  target,
  restart_session,
  ...
) {
  target_version <- sub("^tabpfn==", "", target)
  cli::cli_inform(
    c("!" = "This will delete and rebuild the environment {.val {envname}}.")
  )

  proceed <- !rlang::is_interactive() ||
    tabpfn_confirm(
      paste0(
        "Replace ",
        envname,
        " (tabpfn ",
        installed,
        " -> ",
        target_version,
        ")? (Yes/no) "
      ),
      FALSE
    )

  if (!proceed) {
    cli::cli_inform(
      c("x" = "Cancelled. {.val {envname}} was left unchanged.")
    )
    return(invisible(envname))
  }

  cli::cli_inform(c("i" = "Removing environment {.val {envname}}."))
  remove_env(envname)
  install_env(spec, envname, method, python_version, extra_packages, ...)
  new_version <- env_tabpfn_version(envname)
  cli::cli_inform(
    c("v" = "Installed {.pkg tabpfn} {new_version} into {.val {envname}}.")
  )
  finish_install(envname, restart_session)
}

finish_install <- function(envname, restart_session) {
  maybe_restart_session(restart_session)
  invisible(envname)
}

# ------------------------------------------------------------------------------
# Turn a user-supplied `version` into a pip specification.

resolve_tabpfn_spec <- function(version = "default") {
  if (is.null(version) || version %in% c("default", "release")) {
    return("tabpfn")
  }
  check_string(version)
  # Already a pip specification (contains a version operator)?
  if (grepl("[=<>!~ ]", version)) {
    if (grepl("tabpfn", version, fixed = TRUE)) {
      return(version)
    }
    return(paste0("tabpfn", version))
  }
  paste0("tabpfn==", version)
}

# ------------------------------------------------------------------------------
# Thin wrappers around side effects, isolated for testing / debugging.

# nocov start
pypi_latest_version <- function(package = "tabpfn") {
  url <- paste0("https://pypi.org/pypi/", package, "/json")
  jsonlite::fromJSON(url)$info$version
}

env_exists <- function(envname) {
  reticulate::virtualenv_exists(envname)
}

env_tabpfn_version <- function(envname) {
  pkgs <- reticulate::py_list_packages(envname = envname)
  row <- pkgs[pkgs$package == "tabpfn", , drop = FALSE]
  if (nrow(row) == 0) {
    return(NULL)
  }
  row$version[[1]]
}

install_env <- function(
  spec,
  envname,
  method,
  python_version,
  extra_packages,
  ...
) {
  reticulate::py_install(
    packages = c(spec, extra_packages),
    envname = envname,
    method = method,
    python_version = python_version,
    ...
  )
}

remove_env <- function(envname) {
  reticulate::virtualenv_remove(envname, confirm = FALSE)
}

py_is_initialized <- function() {
  reticulate::py_available(initialize = FALSE)
}

tabpfn_confirm <- function(prompt, default = TRUE) {
  ans <- tolower(trimws(readline(prompt)))
  if (ans == "") {
    return(default)
  }
  ans %in% c("y", "yes")
}

maybe_restart_session <- function(restart_session) {
  if (
    isTRUE(restart_session) &&
      rlang::is_installed("rstudioapi") &&
      rstudioapi::hasFun("restartSession")
  ) {
    cli::cli_inform(
      c("i" = "Restarting R session to activate the environment.")
    )
    rstudioapi::restartSession()
  } else {
    cli::cli_inform(
      c("i" = "Restart R for the new environment to take effect.")
    )
  }
  invisible()
}
# nocov end
