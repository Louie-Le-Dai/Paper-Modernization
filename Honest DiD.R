# HonestDiD in R
library(HonestDiD)
library(ggplot2)
library(dplyr)

cat("\014")
rm(list = ls())


# Read Stata
betahat_raw <- read.csv("D:/Desktop/MA Econ/Econ 562/Modernization/Results/eventstudy_short.csv")
betahat <- as.numeric(betahat_raw[1, ])

# VCV: 13×13 matrix
sigma <- as.matrix(read.csv("D:/Desktop/MA Econ/Econ 562/Modernization/Results/eventstudy_vcv_short.csv"))

numPrePeriods  <- 3   # pre2 - pre7
numPostPeriods <- 7   # post0 - post6

l_vec <- rep(1/numPostPeriods, numPostPeriods)

# Original CI
originalResults <- HonestDiD::constructOriginalCS(
  betahat        = betahat,
  sigma          = sigma,
  numPrePeriods  = numPrePeriods,
  numPostPeriods = numPostPeriods,
  l_vec          = l_vec
)
cat("\nOriginal 95% CI: [",
    round(originalResults$lb, 4), ",",
    round(originalResults$ub, 4), "]\n")

# Relative Magnitudes
# Mbar from 0-1, step 0.1
delta_rm <- HonestDiD::createSensitivityResults_relativeMagnitudes(
  betahat        = betahat,
  sigma          = sigma,
  numPrePeriods  = numPrePeriods,
  numPostPeriods = numPostPeriods,
  l_vec          = l_vec,
  Mbarvec           = seq(0, 1.0, by = 0.1),
)
delta_rm

delta_rm <- delta_rm %>% rename(M = Mbar)

# Visualize: Relative Magnitudes
p_rm <- HonestDiD::createSensitivityPlot(
  robustResults   = delta_rm,
  originalResults = originalResults
) +
  labs(
    title    = "HonestDiD: emphi_dep (Relative Magnitudes; Shorter Pre-policy Periods)",
    subtitle = "Robust CI as function of allowed pre-trend violation (Mbar)",
    x        = "Mbar",
    y        = "95% Robust Confidence Interval"
  ) +
  geom_hline(yintercept = 0,
             linetype = "dashed", color = "red", linewidth = 0.8) +
  theme_bw(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave(paste0("D:/Desktop/MA Econ/Econ 562/Modernization/Results/honestdid_rm_emphi_dep—short.png"),
       p_rm, width = 8, height = 5, dpi = 300)
