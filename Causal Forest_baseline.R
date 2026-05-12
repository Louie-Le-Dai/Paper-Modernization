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
library(dplyr)

cat("\014")
rm(list = ls())

# For using average difference of pre and post to construct Cross-Sectional dataset
data <- read.csv("D:/Desktop/MA Econ/Econ 562/Modernization/data/cross_sectional_cf_mean.csv")

data$fipstate <- as.numeric(as.factor(data$fipstate))

# Construct X, W (Treatment Variable), Y
X <- data %>%
  dplyr::select(female, hispanic, white, black, asian, other,
                mar, fpl_ratio, bad_hlth, ft_student,
                hsdo, hsg, somcol, colgrd,
                live_wparent, fipstate, ue)

Y <- data$Y_emphi_dep

W <- data$W

keep <- complete.cases(X, Y, W)
X <- X[keep, ]
Y <- Y[keep]
W <- W[keep]

# Construct Causal Forest (Ordinary and Honest)
# CF Body
lm.Y <- lm(Y ~ ., data=X, weights=data$p_weight)
Y.hat <- predict(lm.Y)

cf <- causal_forest(
  X, Y, W,
  Y.hat = Y.hat,
  clusters = data$fipstate,
  sample.weights = data$p_weight,
  num.trees = 1000,
  honesty = TRUE
)

ATE_hat = average_treatment_effect (cf)
paste(ATE_hat)
paste ("90% CI for the ATE:", round (ATE_hat[1],3),"+/-", round ( qnorm (0.90)*ATE_hat[2],4))


vi <- variable_importance(cf)
vi_df <- data.frame(variable = colnames(X), importance = vi) %>%
  arrange(desc(importance))
print(vi_df)


data$cate <- predict(cf)$predictions
summary(data$cate)
hist(data$cate, breaks = 50, col = "steelblue",
     main = "Distribution of CATE", xlab = "Estimated CATE")

# Rank the Variable Importance
best_linear_projection(cf, A=X)

ate_val <- average_treatment_effect(cf)["estimate"]

tau_hat <- predict(cf)$predictions
data$cate <- tau_hat

# CATE Distribution
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
       subtitle = "W = emphi_parent, Y = emphi_dep, Treated subsample (age 19-25)",
       x = "Estimated CATE (parental ESI coverage)",
       y = "Count") +
  theme_bw(base_size = 12)

plot_grid(p1, ncol =1, rel_widths = 1)

# Heterogeneity Visualization
data$edu_group <- case_when(
  data$colgrd == 1 ~ "College grad",
  data$somcol == 1   ~ "Some college",
  data$hsg    == 1   ~ "HS graduate",
  TRUE     ~ "Less than HS"
)
data$edu_group <- factor(data$edu_group, levels = c("Less than HS","HS graduate", "Some college","College grad"))

p2 <- ggplot(data, aes(x = edu_group, y = cate, fill = edu_group)) +
  geom_boxplot(alpha = 0.7, outlier.size = 0.5, outlier.alpha = 0.3) +
  geom_hline(yintercept = ate_val, color = "red",
             linetype = "dashed", linewidth = 0.8) +
  scale_fill_brewer(palette = "Blues", direction = 1) +
  labs(title = "CATE by Education Level",
       subtitle = "Red dashed line = ATE. Higher education → higher CATE (BLP: somcol**, colgrd*)",
       x = NULL, y = "Estimated CATE",
       fill = NULL) +
  theme_bw(base_size = 12) +
  theme(legend.position = "none")

plot_grid(p2, ncol =1, rel_widths = 1)

boxplot(cate ~ emphi_dep_pre, data = data,
        names = c("No Previous Dependent", "Has Previous Dependent"),
        main = "CATE by Previous Dependent",
        ylab = "Estimated CATE", col = "steelblue")
abline(h = ATE_hat[1], col = "red", lwd = 2, lty = 2)


# Policy Tree
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

### TOC Curve
n <- nrow(data)
train <- sample(1:n, 2*n/3)
cf_train <- causal_forest(X[train,], Y[train], W[train])
cf_eval  <- causal_forest(X[-train,], Y[-train], W[-train])

rate <- rank_average_treatment_effect(
  cf_eval,
  predict(cf_train, X[-train,])$predictions
)
plot(rate)   # TOC Curve
