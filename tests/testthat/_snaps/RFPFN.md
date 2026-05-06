# rf_pfn regression - random forest

    Code
      mod_df
    Message
      RF-PFN Random Forest Regression Model
    Output
      
    Message
      Training set
      i 32 data points
      i 10 predictors

---

    Code
      mod_f
    Message
      RF-PFN Random Forest Regression Model
    Output
      
    Message
      Training set
      i 32 data points
      i 10 predictors

# rf_pfn regression - decision tree

    Code
      mod
    Message
      RF-PFN Decision Tree Regression Model
    Output
      
    Message
      Training set
      i 32 data points
      i 10 predictors

# rf_pfn classification - random forest

    Code
      mod_df
    Message
      RF-PFN Random Forest Classification Model
    Output
      
    Message
      Training set
      i 20 data points
      i 2 predictors
      i class levels: "Class1" and "Class2"

---

    Code
      mod_f
    Message
      RF-PFN Random Forest Classification Model
    Output
      
    Message
      Training set
      i 20 data points
      i 2 predictors
      i class levels: "Class1" and "Class2"

# rf_pfn classification - decision tree

    Code
      mod
    Message
      RF-PFN Decision Tree Classification Model
    Output
      
    Message
      Training set
      i 20 data points
      i 2 predictors
      i class levels: "Class1" and "Class2"

# rf_pfn - recipes

    Code
      mod
    Message
      RF-PFN Random Forest Classification Model
    Output
      
    Message
      Training set
      i 20 data points
      i 3 predictors
      i class levels: "Class1" and "Class2"

# rf_pfn - RF-only params error for decision_tree

    `bootstrap` is not supported for `tree_type = "decision_tree"`.

---

    `rf_average_logits` is not supported for `tree_type = "decision_tree"`.

---

    `max_predict_time` is not supported for `tree_type = "decision_tree"`.

# rf_pfn - argument validation

    `max_depth` must be a whole number or `NULL`, not the string "deep".

---

    `min_samples_split` must be a whole number larger than or equal to 1, not the number -1.

---

    `min_samples_leaf` must be a whole number larger than or equal to 1, not the number 0.

---

    `fit_nodes` must be a logical vector, not the string "yes".

---

    `max_features` must be a string, a number, or `NULL`.

---

    `rf_pfn()` is not defined for the number 1.

