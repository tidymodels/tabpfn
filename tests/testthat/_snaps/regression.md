# regression models

    Code
      mod_df
    Message
      
      -- TabPFN-v3 Regression Model --
      
      Training set:
      i 32 data points
      i 10 predictors
    Output
      
    Message
      Device:
      i cpu

---

    Code
      mod_f
    Message
      
      -- TabPFN-v3 Regression Model --
      
      Training set:
      i 32 data points
      i 10 predictors
    Output
      
    Message
      Device:
      i cpu

---

    Code
      mod_mat
    Message
      
      -- TabPFN-v3 Regression Model --
      
      Training set:
      i 32 data points
      i 10 predictors
    Output
      
    Message
      Device:
      i cpu

---

    `tab_pfn()` is not defined for the number 1.

# quantile regression models

    Code
      predict(mod, mtcars[1:3, -1], type = "quantile", quantile_levels = 1.9)
    Condition
      Error in `predict()`:
      ! `quantile_levels` must be a number between 0 and 1, not the number 1.9.

# quantile prediction types

    Code
      predict(mod, mtcars[1:3, -1], type = "quantile")
    Condition
      Error in `predict()`:
      ! `quantile_levels` must be supplied when `type = "quantile"`.

---

    Code
      predict(mod, mtcars[1:3, -1], type = "mean", quantile_levels = 0.5)
    Condition
      Error in `predict()`:
      ! `quantile_levels` can only be supplied when `type = "quantile"`.

---

    Code
      predict(mod, mtcars[1:3, -1], type = "bogus")
    Condition
      Error in `predict()`:
      ! `type` must be one of "mean" or "quantile", not "bogus".

# regression models - recipes

    Code
      mod_rec
    Message
      
      -- TabPFN-v3 Regression Model --
      
      Training set:
      i 20 data points
      i 5 predictors
    Output
      
    Message
      Device:
      i cpu

