# classification models

    Code
      mod_df
    Message
      
      -- TabPFN-v3 Classification Model --
      
      Training set:
      i 20 data points
      i 2 predictors
      i class levels: "Class1" and "Class2"
    Output
      
    Message
      Device:
      i cpu

---

    Code
      mod_f
    Message
      
      -- TabPFN-v3 Classification Model --
      
      Training set:
      i 20 data points
      i 2 predictors
      i class levels: "Class1" and "Class2"
    Output
      
    Message
      Device:
      i cpu

---

    Code
      mod_mat
    Message
      
      -- TabPFN-v3 Classification Model --
      
      Training set:
      i 20 data points
      i 2 predictors
      i class levels: "Class1" and "Class2"
    Output
      
    Message
      Device:
      i cpu

---

    `quantile_levels` is only for regression models.

# classification models - recipes

    Code
      mod_rec
    Message
      
      -- TabPFN-v3 Classification Model --
      
      Training set:
      i 20 data points
      i 3 predictors
      i class levels: "Class1" and "Class2"
    Output
      
    Message
      Device:
      i cpu

# main options

    `num_estimators` must be a whole number, not the string "YES".

---

    `softmax_temperature` must be a number larger than or equal to 2.22044604925031e-16, not the number -1.

---

    `balance_probabilities` must be a logical vector, not the string "nope".

---

    `average_before_softmax` must be a logical vector, not the string "suuuure".

