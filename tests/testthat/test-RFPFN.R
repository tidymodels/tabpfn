exp_rf_cls <- c("rf_pfn", "hardhat_model", "hardhat_scalar")

# ------------------------------------------------------------------------------
# Regression

test_that("rf_pfn regression - random forest", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  pred_ptype <- tibble::tibble(.pred = numeric(0))

  # XY - data frame
  set.seed(166)
  mod_df <- try(rf_pfn(predictors, outcome), silent = TRUE)
  expect_s3_class(mod_df, exp_rf_cls)
  expect_snapshot(mod_df)

  pred_df <- predict(mod_df, mtcars[1:3, -1])
  expect_equal(pred_df[0, ], pred_ptype)
  expect_equal(nrow(pred_df), 3L)

  aug_df <- augment(mod_df, mtcars[1:3, -1])
  expect_s3_class(aug_df, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_df), 3L)
  expect_equal(ncol(aug_df), 11L)

  # Formula
  set.seed(166)
  mod_f <- try(rf_pfn(mpg ~ ., data = mtcars), silent = TRUE)
  expect_s3_class(mod_f, exp_rf_cls)
  expect_snapshot(mod_f)

  pred_f <- predict(mod_f, mtcars[1:3, ])
  expect_equal(pred_f[0, ], pred_ptype)
  expect_equal(nrow(pred_f), 3L)
})

test_that("rf_pfn regression - decision tree", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  pred_ptype <- tibble::tibble(.pred = numeric(0))

  set.seed(166)
  mod <- try(
    rf_pfn(predictors, outcome, tree_type = "decision_tree"),
    silent = TRUE
  )
  expect_s3_class(mod, exp_rf_cls)
  expect_equal(mod$tree_type, "decision_tree")
  expect_snapshot(mod)

  pred <- predict(mod, mtcars[1:3, -1])
  expect_equal(pred[0, ], pred_ptype)
  expect_equal(nrow(pred), 3L)
})

# ------------------------------------------------------------------------------
# Classification

test_that("rf_pfn classification - random forest", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()
  skip_if_not_installed("modeldata")

  data(two_class_dat, package = "modeldata")
  x_tr_df <- two_class_dat[1:20, 1:2]
  y_tr <- two_class_dat$Class[1:20]
  x_te_df <- two_class_dat[21:23, 1:2]

  pred_ptype <- tibble::tibble(
    .pred_Class1 = numeric(0),
    .pred_Class2 = numeric(0),
    .pred_class = factor(character(0), levels = levels(y_tr))
  )

  # XY - data frame
  set.seed(956)
  mod_df <- try(rf_pfn(x_tr_df, y_tr), silent = TRUE)
  expect_s3_class(mod_df, exp_rf_cls)
  expect_snapshot(mod_df)

  pred_df <- predict(mod_df, x_te_df)
  expect_equal(pred_df[0, ], pred_ptype)
  expect_equal(nrow(pred_df), 3L)

  aug_df <- augment(mod_df, x_te_df)
  expect_s3_class(aug_df, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_df), 3L)
  expect_equal(ncol(aug_df), 5L)

  # Formula
  set.seed(956)
  mod_f <- try(rf_pfn(Class ~ ., data = two_class_dat[1:20, ]), silent = TRUE)
  expect_s3_class(mod_f, exp_rf_cls)
  expect_snapshot(mod_f)

  pred_f <- predict(mod_f, x_te_df)
  expect_equal(pred_f[0, ], pred_ptype)
  expect_equal(nrow(pred_f), 3L)
})

test_that("rf_pfn classification - decision tree", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()
  skip_if_not_installed("modeldata")

  data(two_class_dat, package = "modeldata")
  x_tr <- two_class_dat[1:20, 1:2]
  y_tr <- two_class_dat$Class[1:20]
  x_te <- two_class_dat[21:23, 1:2]

  pred_ptype <- tibble::tibble(
    .pred_Class1 = numeric(0),
    .pred_Class2 = numeric(0),
    .pred_class = factor(character(0), levels = levels(y_tr))
  )

  set.seed(956)
  mod <- try(rf_pfn(x_tr, y_tr, tree_type = "decision_tree"), silent = TRUE)
  expect_s3_class(mod, exp_rf_cls)
  expect_equal(mod$tree_type, "decision_tree")
  expect_snapshot(mod)

  pred <- predict(mod, x_te)
  expect_equal(pred[0, ], pred_ptype)
  expect_equal(nrow(pred), 3L)
})

# ------------------------------------------------------------------------------
# Recipe interface

test_that("rf_pfn - recipes", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()
  skip_if_not_installed("recipes")
  skip_if_not_installed("modeldata")

  reticulate::import("torch")
  library(tabpfn)
  suppressPackageStartupMessages(library(recipes))

  data(two_class_dat, package = "modeldata")

  pred_ptype <- tibble::tibble(
    .pred_Class1 = numeric(0),
    .pred_Class2 = numeric(0),
    .pred_class = factor(character(0), levels = levels(two_class_dat$Class))
  )

  rec <- recipe(Class ~ ., data = two_class_dat) |> step_interact(~ A:B)

  set.seed(956)
  mod <- try(rf_pfn(rec, two_class_dat[1:20, ]), silent = TRUE)
  expect_s3_class(mod, exp_rf_cls)
  expect_snapshot(mod)

  pred <- predict(mod, two_class_dat[50:52, ])
  expect_equal(pred[0, ], pred_ptype)
  expect_equal(nrow(pred), 3L)

  aug <- augment(mod, two_class_dat[50:52, ])
  expect_s3_class(aug, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug), 3L)
  expect_equal(ncol(aug), 6L)
})

# ------------------------------------------------------------------------------
# RF-only param errors in DT mode

test_that("rf_pfn - RF-only params error for decision_tree", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  expect_snapshot_error(
    rf_pfn(predictors, outcome, tree_type = "decision_tree", bootstrap = TRUE)
  )
  expect_snapshot_error(
    rf_pfn(
      predictors,
      outcome,
      tree_type = "decision_tree",
      rf_average_logits = TRUE
    )
  )
  expect_snapshot_error(
    rf_pfn(
      predictors,
      outcome,
      tree_type = "decision_tree",
      max_predict_time = 30
    )
  )
})

# ------------------------------------------------------------------------------
# Argument validation

test_that("rf_pfn - argument validation", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  expect_snapshot_error(
    rf_pfn(predictors, outcome, max_depth = "deep")
  )
  expect_snapshot_error(
    rf_pfn(predictors, outcome, min_samples_split = -1)
  )
  expect_snapshot_error(
    rf_pfn(predictors, outcome, min_samples_leaf = 0)
  )
  expect_snapshot_error(
    rf_pfn(predictors, outcome, fit_nodes = "yes")
  )
  expect_snapshot_error(
    rf_pfn(predictors, outcome, max_features = TRUE)
  )
  expect_snapshot_error(
    rf_pfn(1, 2)
  )
})

# ------------------------------------------------------------------------------
# training_set_limit subsampling

test_that("rf_pfn - training_set_limit subsampling", {
  skip_if(!is_tab_pfn_installed())
  skip_on_cran()

  set.seed(166)
  mod <- try(
    rf_pfn(predictors, outcome, training_set_limit = 10L),
    silent = TRUE
  )
  expect_s3_class(mod, exp_rf_cls)
  expect_lte(mod$training[1], 10L)

  pred <- predict(mod, mtcars[1:3, -1])
  expect_equal(nrow(pred), 3L)
})
