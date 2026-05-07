test_that('control values', {
  set.seed(822)
  ctrl <- control_tab_pfn(
    n_preprocessing_jobs = 2L,
    device = "cpu",
    ignore_pretraining_limits = TRUE,
    inference_precision = "float32",
    fit_mode = "low_memory",
    memory_saving_mode = TRUE,
    random_state = 12345L
  )

  expect_s3_class(ctrl, "control_tab_pfn")
  expect_equal(ctrl$n_preprocessing_jobs, 2L)
  expect_equal(ctrl$device, "cpu")
  expect_equal(ctrl$ignore_pretraining_limits, TRUE)
  expect_equal(ctrl$inference_precision, "float32")
  expect_equal(ctrl$fit_mode, "low_memory")
  expect_equal(ctrl$memory_saving_mode, TRUE)
  expect_equal(ctrl$random_state, 12345L)

  set.seed(822)
  expect_snapshot(ctrl)

  set.seed(822)
  expect_snapshot(control_tab_pfn(random_state = 1))
})

test_that('control dot args - model_path', {
  skip_if_no_tabpfn()
  skip_if_not_installed("modeldata")

  tab_pfn_py <- import_tabpfn()
  model_path <- tab_pfn_py$TabPFNClassifier$create_default_for_version(
    "v2.6"
  )$model_path

  data(two_class_dat, package = "modeldata")
  x_tr <- two_class_dat[1:20, 1:2]
  y_tr <- two_class_dat$Class[1:20]

  set.seed(1)
  mod <- tab_pfn(x_tr, y_tr, control = control_tab_pfn(model_path = model_path))

  expect_s3_class(mod, exp_cls)
})

test_that('control dot args - invalid parameter fails', {
  skip_if_no_tabpfn()
  skip_if_not_installed("modeldata")

  data(two_class_dat, package = "modeldata")
  x_tr <- two_class_dat[1:20, 1:2]
  y_tr <- two_class_dat$Class[1:20]

  expect_error(
    tab_pfn(x_tr, y_tr, control = control_tab_pfn(not_a_real_param = TRUE))
  )
})
