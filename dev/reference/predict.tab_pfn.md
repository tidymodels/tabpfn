# Predict using `TabPFN`

Predict using `TabPFN`

## Usage

``` r
# S3 method for class 'tab_pfn'
predict(object, new_data, type = NULL, quantile_levels = NULL, ...)

# S3 method for class 'tab_pfn'
augment(x, new_data, type = NULL, quantile_levels = NULL, ...)
```

## Arguments

- object, x:

  A `tab_pfn` object.

- new_data:

  A data frame or matrix of new predictors.

- type:

  The type of prediction. For classification, can be `"class"` or
  `"prob"`. Defaults to `NULL` which gives all prediction types
  possible. For regression, can be `"mean"` or `"quantile"`; when
  `"quantile"`, `quantile_levels` must be supplied.

- quantile_levels:

  A numeric vector of probabilities, sorted in increasing order, at
  which to predict the outcome distribution. Regression only; required
  when `type = "quantile"` and must otherwise be `NULL`.

- ...:

  Not used, but required for extensibility.

## Value

[`predict()`](https://rdrr.io/r/stats/predict.html) returns a tibble of
predictions and
[`augment()`](https://generics.r-lib.org/reference/augment.html) appends
the columns in `new_data`. In either case, the number of rows in the
tibble is guaranteed to be the same as the number of rows in `new_data`.

For regression data, the prediction is in the column `.pred`. For
classification, the class predictions are in `.pred_class` and the
probability estimates are in columns with the pattern `.pred_{level}`
where `level` is the levels of the outcome factor vector.

When `quantile_levels` is given, regression results also have a
`.pred_quantile` column of
[`hardhat::quantile_pred()`](https://hardhat.tidymodels.org/reference/quantile_pred.html)
values.

## Examples

``` r
if (FALSE) { # \dontrun{
if (rlang::is_installed(c("MASS", "ggplot2")) &
     is_tab_pfn_installed() &
     interactive()) {
  library(ggplot2)

  in_tr <- seq(1, nrow(mcycle), by = 2)
  mcycle_tr <- MASS::mcycle[in_tr, ]
  mcycle_te <- MASS::mcycle[-in_tr, ]

  mcycle_grid <-
   dplyr::tibble(times = seq(min(mcycle$times), max(mcycle$times), length.out = 200))
  mcycle_grid$.row <- seq_len(nrow(mcycle_grid))

  fit <- tab_pfn(accel ~ times, data = mcycle_tr)

  # ------------------------------------------------------------------------------
  # Predict mean acceleration

  mean_pred <- augment(fit, mcycle_grid)

  mean_p <-
   mean_pred |>
   ggplot(aes(times)) +
   geom_point(data = mcycle_te, aes(y = accel), alpha = 1 / 2) +
   geom_line(aes(y = .pred))

  #------------------------------------------------------------------------------Predict 5 %, 50%
  # Predict 5%, 50%, and 90% quantiles of acceleration

  q_pred <-
   predict(fit,
           mcycle_grid,
           type = "quantile",
           quantile_levels = c(0.1, 0.5, 0.9))
  q_pred$.row <- seq_len(nrow(q_pred))

  q_pred_longer <-
   q_pred$.pred_quantile |>
   dplyr::as_tibble() |>
   dplyr::full_join(mcycle_grid, by = ".row") |>
   dplyr::mutate(level = format(.quantile_levels))

  mean_p +
   geom_line(
     data = q_pred_longer,
     aes(y = .pred_quantile, col = level, group = level)
   )
}
} # }
```
