test_that('classification models', {
  skip_if_no_tabpfn()
  skip_if_not_installed("modeldata")
  # Force CPU so the printed device is deterministic across hardware.
  local_tabpfn_cpu()

  #-----------------------------------------------------------------------------

  data(two_class_dat, package = "modeldata")
  x_tr_df <- two_class_dat[1:20, 1:2]
  x_tr_mat <- as.matrix(x_tr_df)
  y_tr <- two_class_dat$Class[1:20]

  x_te_df <- two_class_dat[21:23, 1:2]
  x_te_mat <- as.matrix(x_te_df)

  pred_ptype <-
    tibble::tibble(
      .pred_Class1 = numeric(0),
      .pred_Class2 = numeric(0),
      .pred_class = factor(0, levels = levels(two_class_dat$Class))
    )

  #-----------------------------------------------------------------------------

  set.seed(956)
  mod_df <- try(tab_pfn(x_tr_df, y_tr), silent = TRUE)
  expect_s3_class(mod_df, exp_cls)
  expect_snapshot(mod_df)

  pred_df <- predict(mod_df, x_te_df)
  expect_equal(pred_df[0, ], pred_ptype)
  expect_equal(nrow(pred_df), 3L)

  pred_cls_df <- predict(mod_df, x_te_df, type = "class")
  expect_equal(pred_cls_df[0, ], pred_ptype[, ".pred_class"])
  expect_equal(nrow(pred_cls_df), 3L)

  pred_df <- predict(mod_df, x_te_df, type = "prob")
  expect_equal(pred_df[0, ], pred_ptype[, 1:2])
  expect_equal(nrow(pred_df), 3L)

  aug_df <- augment(mod_df, x_te_df)
  expect_s3_class(aug_df, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_df), 3L)
  expect_equal(ncol(aug_df), 5L)

  #-----------------------------------------------------------------------------

  set.seed(956)
  mod_f <- try(tab_pfn(Class ~ ., data = two_class_dat[1:20, ]), silent = TRUE)
  expect_s3_class(mod_f, exp_cls)
  expect_snapshot(mod_f)

  pred_f <- predict(mod_f, x_tr_df[21:23, ])
  expect_equal(pred_f[0, ], pred_ptype)
  expect_equal(nrow(pred_f), 3L)

  aug_f <- augment(mod_f, x_tr_df[21:23, ])
  expect_s3_class(aug_f, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_f), 3L)
  expect_equal(ncol(aug_f), 5L)

  #-----------------------------------------------------------------------------

  set.seed(956)
  mod_mat <- try(tab_pfn(x_tr_mat, y_tr), silent = TRUE)
  expect_s3_class(mod_mat, exp_cls)
  expect_snapshot(mod_mat)

  pred_mat <- predict(mod_mat, x_te_mat)
  expect_equal(pred_mat[0, ], pred_ptype)
  expect_equal(nrow(pred_mat), 3L)

  aug_mat <- augment(mod_mat, x_tr_df[21:23, ])
  expect_s3_class(aug_mat, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_mat), 3L)
  expect_equal(ncol(aug_mat), 5L)

  expect_snapshot(predict(mod_mat, x_te_mat, quantile_levels = 0.5), error = TRUE)
  expect_snapshot(predict(mod_mat, x_te_mat, type = "quantile"), error = TRUE)
})

test_that('classification models - recipes', {
  skip_if_no_tabpfn()
  skip_if_not_installed("modeldata")
  skip_if_not_installed("recipes")
  # Force CPU so the printed device is deterministic across hardware.
  local_tabpfn_cpu()

  reticulate::import("torch")

  library(tabpfn)
  suppressPackageStartupMessages(library(recipes))

  #-----------------------------------------------------------------------------

  data(two_class_dat, package = "modeldata")

  pred_ptype <-
    tibble::tibble(
      .pred_Class1 = numeric(0),
      .pred_Class2 = numeric(0),
      .pred_class = factor(0, levels = levels(two_class_dat$Class))
    )

  #-----------------------------------------------------------------------------

  rec <-
    recipe(Class ~ ., data = two_class_dat) |>
    step_interact(~ A:B)

  set.seed(956)
  mod_rec <- try(tab_pfn(rec, two_class_dat[1:20, ]), silent = TRUE)
  expect_s3_class(mod_rec, exp_cls)
  expect_snapshot(mod_rec)

  pred_rec <- predict(mod_rec, two_class_dat[50:52, ])
  expect_equal(pred_rec[0, ], pred_ptype)
  expect_equal(nrow(pred_rec), 3L)

  aug_rec <- augment(mod_rec, two_class_dat[50:52, ])
  expect_s3_class(aug_rec, c("tbl_df", "tbl", "data.frame"))
  expect_equal(nrow(aug_rec), 3L)
  expect_equal(ncol(aug_rec), 6L)
})

test_that('main options', {
  skip_if_no_tabpfn()
  set.seed(956)
  expect_snapshot_error(
    tab_pfn(Class ~ ., data = two_class_dat, num_estimators = "YES")
  )
  expect_snapshot_error(
    tab_pfn(Class ~ ., data = two_class_dat, softmax_temperature = -1)
  )
  expect_snapshot_error(
    tab_pfn(Class ~ ., data = two_class_dat, balance_probabilities = "nope")
  )
  expect_snapshot_error(
    tab_pfn(Class ~ ., data = two_class_dat, average_before_softmax = "suuuure")
  )
})
