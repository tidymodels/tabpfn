test_that("show_env_var returns value when set", {
  withr::with_envvar(
    new = c(TABPFN_TEST_VAR = "hello"),
    expect_equal(tabpfn:::show_env_var("TABPFN_TEST_VAR"), "hello")
  )
})

test_that("show_env_var returns not set when empty", {
  withr::with_envvar(
    new = c(TABPFN_TEST_VAR = ""),
    expect_equal(tabpfn:::show_env_var("TABPFN_TEST_VAR"), "<not set>")
  )
})

test_that('regression models', {
  skip_if_no_tabpfn()
  # Force CPU so the printed device is deterministic across hardware.
  local_tabpfn_cpu()

  pred_ptype <- tibble::tibble(.pred = numeric(0))

  #-----------------------------------------------------------------------------

  set.seed(166)
  mod_df <- try(tab_pfn(predictors, outcome), silent = TRUE)
  expect_s3_class(mod_df, exp_cls)
  expect_snapshot(mod_df)

  pred_df <- predict(mod_df, mtcars[1:3, -1])
  expect_equal(pred_df[0, ], pred_ptype)
  expect_equal(nrow(pred_df), 3L)

  aug_df <- augment(mod_df, mtcars[1:3, -1])
  expect_s3_class(aug_df, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_df), 3L)
  expect_equal(ncol(aug_df), 11L)

  #-----------------------------------------------------------------------------

  set.seed(166)
  mod_f <- try(tab_pfn(mpg ~ ., data = mtcars), silent = TRUE)
  expect_s3_class(mod_f, exp_cls)
  expect_snapshot(mod_f)

  pred_f <- predict(mod_f, mtcars[1:3, -1])
  expect_equal(pred_f[0, ], pred_ptype)
  expect_equal(nrow(pred_f), 3L)

  aug_f <- augment(mod_f, mtcars[1:3, -1])
  expect_s3_class(aug_f, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_f), 3L)
  expect_equal(ncol(aug_f), 11L)

  #-----------------------------------------------------------------------------

  set.seed(166)
  mod_mat <- try(tab_pfn(as.matrix(predictors), outcome), silent = TRUE)
  expect_s3_class(mod_mat, exp_cls)
  expect_snapshot(mod_mat)

  pred_mat <- predict(mod_mat, mtcars[1:3, -1])
  expect_equal(pred_mat[0, ], pred_ptype)
  expect_equal(nrow(pred_mat), 3L)

  aug_mat <- augment(mod_mat, mtcars[1:3, -1])
  expect_s3_class(aug_mat, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_mat), 3L)
  expect_equal(ncol(aug_mat), 11L)

  #-----------------------------------------------------------------------------

  expect_snapshot_error(
    tab_pfn(1, 2)
  )
})

test_that('quantile regression models', {
  skip_if_no_tabpfn()

  quantile_levels <- c(0.1, 0.5, 0.9)
  pred_ptype <- tibble::tibble(
    .pred = numeric(0),
    .pred_quantile = hardhat::quantile_pred(
      matrix(numeric(0), ncol = length(quantile_levels)),
      quantile_levels
    )
  )

  set.seed(166)
  mod <- tab_pfn(predictors, outcome)

  pred <- predict(
    mod,
    mtcars[1:3, -1],
    type = "quantile",
    quantile_levels = quantile_levels
  )
  expect_equal(pred[0, ], pred_ptype)
  expect_equal(nrow(pred), 3L)
  expect_equal(pred$.pred, predict(mod, mtcars[1:3, -1])$.pred)
  expect_true(all(apply(as.matrix(pred$.pred_quantile), 1, diff) >= 0))

  expect_no_error(
    predict(
      mod,
      mtcars[1:3, -1],
      type = "quantile",
      quantile_levels = 0.5
    )
  )

  expect_snapshot(
    predict(mod, mtcars[1:3, -1], type = "quantile", quantile_levels = 1.9),
    error = TRUE
  )

  aug <- augment(
    mod,
    mtcars[1:3, -1],
    type = "quantile",
    quantile_levels = quantile_levels
  )
  expect_equal(aug[, names(pred)], pred)
  expect_equal(ncol(aug), 12L)
})

test_that('quantile prediction types', {
  skip_if_no_tabpfn()

  set.seed(166)
  mod <- tab_pfn(predictors, outcome)

  expect_snapshot(
    predict(mod, mtcars[1:3, -1], type = "quantile"),
    error = TRUE
  )
  pred <- predict(
    mod,
    mtcars[1:3, -1],
    type = "quantile",
    quantile_levels = 0.5
  )
  expect_s3_class(pred, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(pred), 3L)
  expect_true("quantile_pred" %in% class(pred$.pred_quantile))

  expect_snapshot(
    predict(mod, mtcars[1:3, -1], type = "mean", quantile_levels = 0.5),
    error = TRUE
  )
  expect_snapshot(predict(mod, mtcars[1:3, -1], type = "bogus"), error = TRUE)
})

test_that('training_set_limit with data frame and matrix interfaces', {
  skip_if_no_tabpfn()
  skip_if_not_installed("recipes")

  set.seed(166)
  mod_df <- try(
    tab_pfn(
      predictors,
      outcome,
      training_set_limit = 20,
      control = control_tab_pfn(ignore_pretraining_limits = TRUE)
    ),
    silent = TRUE
  )
  expect_equal(mod_df$training[1], 20)

  set.seed(166)
  mod_mat <- try(
    tab_pfn(
      as.matrix(predictors),
      outcome,
      training_set_limit = 20,
      control = control_tab_pfn(ignore_pretraining_limits = TRUE)
    ),
    silent = TRUE
  )
  expect_equal(mod_mat$training[1], 20)

  set.seed(166)
  rec <- recipes::recipe(mpg ~ ., data = mtcars)
  mod_rec <- try(
    tab_pfn(
      rec,
      mtcars,
      training_set_limit = 20,
      control = control_tab_pfn(ignore_pretraining_limits = TRUE)
    ),
    silent = TRUE
  )
  expect_equal(mod_rec$training[1], 20)
})

test_that('reproducible results', {
  skip_if_no_tabpfn()

  set.seed(166)
  mod_1 <- try(tab_pfn(predictors, outcome), silent = TRUE)
  pred_1 <- predict(mod_1, mtcars[1:3, -1])

  set.seed(166)
  mod_2 <- try(tab_pfn(predictors, outcome), silent = TRUE)
  pred_2 <- predict(mod_2, mtcars[1:3, -1])

  expect_equal(pred_1, pred_2)

  set.seed(774)
  mod_3 <- try(tab_pfn(predictors, outcome), silent = TRUE)
  pred_3 <- predict(mod_3, mtcars[1:3, -1])

  expect_false(all(pred_1$.pred == pred_3$.pred))

  set.seed(166)
  mod_4 <- try(tab_pfn(predictors, outcome, num_estimators = 1), silent = TRUE)
  pred_4 <- predict(mod_4, mtcars[1:3, -1])

  expect_false(all(pred_1$.pred == pred_4$.pred))
})


test_that('regression models - recipes', {
  skip_if_no_tabpfn()
  skip_if_not_installed("modeldata")
  skip_if_not_installed("recipes")
  # Force CPU so the printed device is deterministic across hardware.
  local_tabpfn_cpu()

  reticulate::import("torch")

  library(tabpfn)
  library(recipes)
  data(Chicago, package = "modeldata")

  pred_ptype <- tibble::tibble(.pred = numeric(0))

  #-----------------------------------------------------------------------------

  rec <-
    recipe(ridership ~ Austin + Quincy_Wells + date, data = Chicago) |>
    step_date(date) |>
    step_rm(date)

  set.seed(166)
  mod_rec <- try(tab_pfn(rec, Chicago[1:20, ]), silent = TRUE)
  expect_s3_class(mod_rec, exp_cls)
  expect_snapshot(mod_rec)

  pred_rec <- predict(mod_rec, Chicago[50:52, ])
  expect_equal(pred_rec[0, ], pred_ptype)
  expect_equal(nrow(pred_rec), 3L)

  aug_rec <- augment(mod_rec, Chicago[50:52, ])
  expect_s3_class(aug_rec, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_rec), 3L)
  expect_equal(ncol(aug_rec), 51L)
})
