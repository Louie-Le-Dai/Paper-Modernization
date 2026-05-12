### Section 5: Policy Suggestion ###
library(haven)
library(dplyr)
library(grf)
library(ggplot2)
library(randomForest)

cat("\014")
rm(list = ls())

# Read Data
df <- read_dta("D:/Desktop/MA Econ/Econ 562/Modernization/data/depcov_dataset.dta")
df$age <- as.integer(df$age)
df$fedelig    <- as.integer(df$age >= 19 & df$age < 26)
df$after_oct10 <- as.integer((df$year == 2010 & df$month >= 10) | df$year >= 2011)
df$mar_sep10   <- as.integer(df$year == 2010 & df$month >= 3 & df$month <= 9)

df$famcov_pre <- NA
df$famcov_pre[df$other_dep_pre == 1 & df$emphi_dep_pre == 0] <- 1
df$famcov_pre[df$other_dep_pre == 0 & 
                df$emphi_p_pre == 1 & 
                df$emphi_dep_pre == 0] <- 0
table(df$famcov_pre, useNA = "always")

# post implementation take last observation
df_clean <- df[df$mar_sep10 == 0, ]
post <- df_clean[df_clean$after_oct10 == 1, ]

# Covariate
x_cols <- c("female", "hispanic", "white", "black", "asian",
            "mar", "fpl_ratio", "bad_hlth", "ft_student",
            "hsdo", "hsg", "somcol", "colgrd",
            "live_wparent", "fipstate", "ue", "emphi_dep_pre", "anyhi_pre",
            "famcov_pre") 

cs_parent <- post %>%
  group_by(groupid) %>%
  arrange(year, month) %>%
  slice_tail(n = 1) %>%
  ungroup() %>%
  filter(
    !is.na(fedelig),
    !is.na(emphi_dep),
    emphi_parent == 1  # Keep observations with parent with ESI
  )

# In emphi_parent==1, in post period, fedelig==1:
# Y = 1: non-taker (emphi_dep==0 and anyhi==0)
# Y = 0: taker (emphi_dep==1)
cs_nontaker <- cs_parent %>%
  filter(fedelig == 1) %>%
  mutate(non_taker = as.integer(emphi_dep == 0 & anyhi == 0)) # Logically, if anyhi=0, emphi_dep must be 0, we set both for guarantee

cs_nontaker <- cs_nontaker %>%
  select(non_taker, female, hispanic, white, black,
         mar, fpl_ratio, bad_hlth, ft_student,
         hsdo, hsg, somcol, colgrd,
         live_wparent, ue, anyhi_pre) %>%
  mutate(across(everything(),
                ~ifelse(is.na(.), median(., na.rm = TRUE), .))) %>%
  filter(!is.na(non_taker))

logit_fit <- glm(non_taker ~ female + hispanic + white + black +
                   mar + fpl_ratio + bad_hlth + ft_student +
                   hsdo + hsg + somcol + colgrd +
                   live_wparent + ue + anyhi_pre,
                 data = cs_nontaker,
                 family = binomial(link = "logit"))

summary(logit_fit)


# See actual non-taker ratio
p_nontaker <- mean(cs_nontaker$non_taker)
cat("Non-taker rate:", p_nontaker, "\n")


n_minority <- sum(cs_nontaker$non_taker == 1)
rf_fit <- randomForest(
  as.factor(non_taker) ~ .,
  data = cs_nontaker,
  ntree = 1000,
  importance = TRUE,
  sampsize = c("0" = 6, "1" = 1)  
)

# Variable importance
varImpPlot(rf_fit, main = "Variable Importance: Non-taker Prediction")

# Predict Probability
cs_nontaker$prob_nontaker <- predict(rf_fit, type = "prob")[, 2]


# Divide the predicted probabilities into 10 groups and see the actual non-taker ratio.
cs_nontaker$prob_decile <- ntile(cs_nontaker$prob_nontaker, 10)

calibration <- cs_nontaker %>%
  group_by(prob_decile) %>%
  summarise(
    mean_pred = mean(prob_nontaker),
    mean_actual = mean(non_taker),
    n = n()
  )

ggplot(calibration, aes(x = mean_pred, y = mean_actual)) +
  geom_point(size = 3) +
  geom_abline(slope = 1, intercept = 0,
              color = "red", linetype = "dashed") +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  labs(title = "Calibration Plot: Non-taker Prediction",
       x = "Predicted Probability",
       y = "Actual Non-taker Rate") +
  theme_minimal()

# Variable importance
varImpPlot(rf_fit,
           main = "Variable Importance: Non-taker Prediction",
           type = 1)  

importance_df <- as.data.frame(importance(rf_fit)) %>%
  rownames_to_column("variable") %>%
  arrange(desc(MeanDecreaseAccuracy))

ggplot(importance_df,
       aes(x = reorder(variable, MeanDecreaseAccuracy),
           y = MeanDecreaseAccuracy)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Variable Importance: Non-taker Prediction",
       x = "", y = "Mean Decrease in Accuracy") +
  theme_minimal()

