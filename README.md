# Paper Modernization: ACA Dependent Coverage Mandate

This repository contains a modernization and methodological extension of the paper:

> *Effects of Federal Policy to Insure Young Adults: Evidence from the 2010 Affordable Care Act’s Dependent-Coverage Mandate*

The original paper studies how the Affordable Care Act (ACA) dependent coverage mandate affected insurance coverage and labor market outcomes among young adults aged 19–25 using a Difference-in-Differences (DiD) framework.

This project modernizes the original empirical design using recent developments in:
- semiparametric DiD estimation,
- causal machine learning,
- treatment effect heterogeneity analysis,
- sensitivity analysis for parallel trends,
- and predictive policy targeting.

The project does **not** attempt to overturn the original conclusions. Instead, it evaluates the robustness of the original findings under modern econometric frameworks and extends the policy interpretation through heterogeneous treatment effect estimation.

---

# Original Paper

The original paper uses:
- Linear Probability Model (LPM) Difference-in-Differences,
- Triple Difference (DDD),
- subgroup regressions,
- and placebo timing tests

to estimate the effects of the ACA dependent coverage expansion on:
- insurance take-up,
- employer-sponsored dependent coverage,
- labor market outcomes,
- and substitution across insurance sources.

The treatment group consists of individuals aged 19–25 after ACA implementation.

---

# Modernization Contributions

This project introduces several modern econometric and machine learning approaches:

| Area | Modernization |
|---|---|
| Functional Form Robustness | Doubly Robust DiD (DRDID) |
| DDD Robustness | Doubly Robust DDD (DRDDD) |
| Dynamic Identification | Event Study + HonestDiD |
| Treatment Heterogeneity | Causal Forest |
| Heterogeneity Interpretation | Best Linear Projection (BLP) |
| Policy Targeting | TOC Curve |
| Robustness | Permutation Placebo Tests |
| Non-Takeup Prediction | Random Forest Classification |

---

# Main Findings

The modernization confirms the paper’s central conclusion that the ACA dependent coverage mandate significantly increased parental employer-sponsored insurance take-up among young adults.

Additional findings include:

- The main treatment effects remain robust under semiparametric DRDID and DRDDD estimators.
- HonestDiD suggests that the implementation-period effects remain credible under moderate deviations from parallel trends.
- Causal Forest reveals substantial treatment effect heterogeneity across:
  - education,
  - marital status,
  - student status,
  - and prior dependent coverage.
- Policy targeting value emerges mainly during the implementation period rather than the enactment period.
- Random Forest analysis suggests that pre-policy insurance status and Hispanic ethnicity are major predictors of non-takeup.

---

# Repository Structure

## Data Preparation

| File | Purpose | Language |
|---|---|---|
| `depcov run regressions.dta` | Original replication data preparation | Stata |

---

## Modern Estimation

| Method | File(s) | Language |
|---|---|---|
| DRDID | `drdid.do` | Stata |
| DRDDD | `DRDDD.do` | Stata |
| Event Study | `Event Study.do` | Stata |
| HonestDiD | `Honest DiD.R` | R |
| Placebo Tests | `Placebo Test.do` | Stata |
| Permutation Placebo | `Permutation placebo.do` | Stata |

---

## Causal Machine Learning

| Method | File(s) | Language |
|---|---|---|
| Cross-sectional Construction | `Create cross sectional.py` | Python |
| Mean Construction | `cross sectional mean.py` | Python |
| Causal Forest | `Causal Forest1.R` | R |
| Baseline Forest Estimation | `Causal Forest baseline.R` | R |
| Policy Targeting | `Policy.R` | R |

---

# Empirical Workflow

```text
Original replication package
        ↓
Data transformation
        ↓
DRDID / DRDDD estimation
        ↓
Event Study + HonestDiD
        ↓
Causal Forest estimation
        ↓
BLP heterogeneity analysis
        ↓
TOC targeting analysis
        ↓
Permutation placebo tests
        ↓
Random Forest policy targeting
```

---

# Software Used

- Stata 18
- R
  - grf
  - HonestDiD
  - ggplot2
  - dplyr
- Python
  - pandas
  - numpy
  - scikit-learn

---

# Replication Notes

This project uses transformed versions of the original replication package data to accommodate semiparametric estimators and causal machine learning methods.

Some estimators require:
- collapsing panel observations into cross-sectional settings,
- reconstructing two-period DiD structures,
- or generating transformed outcomes.

Therefore, certain estimates are not numerically identical to the original paper by construction.

---

# References

- Sant’Anna and Zhao (2020)
- Rambachan and Roth (2023)
- Wager and Athey (2018)
- Chernozhukov et al. (2018)
- Sylvia et al. (2021)

See the full modernization report for detailed references and methodology discussion.
