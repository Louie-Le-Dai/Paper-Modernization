### LOAD PACkages ###
library(devtools)
library(tidyverse)
library(grf)
library(haven)
library(cowplot)
library(DiagrammeR)
library(plotly)
library(Rcpp)
library(writexl)
library(readxl)
library(twang)
library(openxlsx)
library(policytree)
library(maq)
library(lfe)
library(scatterplot3d)
library(DescTools)

cat("\014")
rm(list = ls())

# For using the very last observation to construct Cross-Sectional dataset
data <- read.csv("D:/Desktop/MA Econ/Econ 562/Modernization/data/cross-sectional.csv")

data$fipstate <- as.numeric(as.factor(data$fipstate))

# Construct X, W, Y
X <- data %>%
  dplyr::select(female, hispanic, white, black, asian,
                mar, fpl_ratio, bad_hlth, student,
                hsdo, hsg, somcol, colgrd,
                live_wparent, fipstate, ue
)

Y <- data$emphi_dep
W <- data$treat

keep <- complete.cases(X, Y, W)
X <- X[keep, ]
Y <- Y[keep]
W <- W[keep]

# Construct CF
cf <- causal_forest(
  X, Y, W,
  clusters = data$fipstate,
  sample.weights = data$p_weight,
  num.trees = 1000,
  honesty = TRUE
)

test_calibration(cf)

tree_1 = get_tree(cf, 1)
plot(tree_1)

ATE_hat = average_treatment_effect (cf)
paste(ATE_hat)
paste ("90% CI for the ATE:", round (ATE_hat[1],3),"+/-", round ( qnorm (0.90)*ATE_hat[2],4))


### Rank the Variable Importance
best_linear_projection(cf, A=X)
cf %>% variable_importance() %>% as.data.frame() %>% mutate(variable = colnames(cf$X.orig)) %>% arrange(desc(V1))

ate_val <- average_treatment_effect(cf)["estimate"]

tau_hat <- predict(cf)$predictions
data$cate <- tau_hat



### Visualization
p1 <- ggplot(data, aes(x = cate)) +
  geom_histogram(bins = 40, fill = "steelblue", color = "white", alpha = 0.8) +
  geom_vline(xintercept = ate_val, color = "red",
             linewidth = 1, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "gray40",
             linewidth = 0.5, linetype = "dotted") +
  annotate("text", x = ate_val + 0.005, y = Inf,
           label = paste0("ATE = ", round(ate_val, 3)),
           hjust = 0, vjust = 2, color = "red", size = 3.5) +
  labs(title = "Distribution of Individual CATE Estimates",
       subtitle = " Y = emphi_dep, Treated subsample (age 19-25)",
       x = "Estimated CATE (parental ESI coverage)",
       y = "Count") +
  theme_bw(base_size = 12)

plot_grid(p1, ncol =1, rel_widths = 1)

data$edu_group <- case_when(
  data$colgrd == 1    ~ "College grad",
  data$somcol == 1    ~ "Some college",
  data$hsg    == 1      ~ "HS graduate",
  data$hsdo == 1    ~ "HS Dropout",
  TRUE  ~ "Less than HS"
)
data$edu_group <- factor(data$edu_group, levels = c("Less than HS", "HS Dropout", "HS graduate", "Some college","College grad"))

p2 <- ggplot(data, aes(x = edu_group, y = cate, fill = edu_group)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.5, outlier.alpha = 0.3) +
  geom_hline(yintercept = ate_val, color = "red",
             linetype = "dashed", linewidth = 0.8) +
  scale_fill_brewer(palette = "Blues", direction = 1) +
  labs(title = "CATE by Education Level (Enactment Period)",
       subtitle = "Red dashed line = ATE. Higher education → higher CATE (BLP: somcol**, colgrd*)",
       x = NULL, y = "Estimated CATE",
       fill = NULL) +
  theme_bw(base_size = 12) +
  theme(legend.position = "none")

plot_grid(p2, ncol =1, rel_widths = 1)

boxplot(cate ~ live_wparent, data = data,
        names = c("No Previous Dependent", "Has Previous Dependent"),
        main = "CATE by Previous Dependent (Enactment)",
        ylab = "Estimated CATE", col = "steelblue")
abline(h = ATE_hat[1], col = "red", lwd = 2, lty = 2)


boxplot(cate ~ mar, data = data,
        names = c("Single", "Married"),
        main = "CATE by Martial Status (Enactment)",
        ylab = "Estimated CATE", col = "steelblue")
abline(h = ATE_hat[1], col = "red", lwd = 2, lty = 2)

boxplot(cate ~ ft_student, data = data,
        names = c("Non-student", "Student"),
        main = "CATE by Student Status",
        ylab = "Estimated CATE", col = "steelblue")
abline(h = ATE_hat[1], col = "red", lwd = 2, lty = 2)


### Policy Tree (Not Suitable)
tau_hat <- predict(cf)$predictions
Gamma <- cbind(control = rep(0, length(tau_hat)), treat   = tau_hat)
pt <- policy_tree(X = as.matrix(X), Gamma = Gamma, depth = 2)
plot(pt)

policy_assignment <- predict(pt, as.matrix(X))
table(policy_assignment)

# Predict the treatment assignment {1, 2} for each sample. 
predicted <- predict(pt, X)

# Visualization FAILED because of dummies
plot(X[, 15], X[, 14], col = predicted)
legend("topright", c("control", "treat"), col = c(1, 2), pch = 19)
abline(0, -1, lty = 2)

# Separate train/evaluation group，validate heterogeneity magnitude via RATE
n <- nrow(data)
train <- sample(1:n, 2*n/3)
cf_train <- causal_forest(X[train,], Y[train], W[train])
cf_eval  <- causal_forest(X[-train,], Y[-train], W[-train])

rate <- rank_average_treatment_effect(
  cf_eval,
  predict(cf_train, X[-train,])$predictions
)
plot(rate, main = 'Target Operator Characteristic')   # TOC
