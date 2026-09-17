# Singapore HDB Resale Price Prediction & Econometric Analysis

An econometric modeling study analyzing the primary valuation drivers of Singapore Housing & Development Board (HDB) resale transactions using Base R and ordinary least squares (OLS) regression.

---

## Project Overview
Valuing public residential real estate requires accounting for non-linear depreciation and spatial premiums. This project formulates, diagnoses, and refines multiple linear regression models using July 2020 resale transaction data to isolate the structural drivers of HDB pricing.

* **Dataset:** Singapore HDB Resale Flat Prices (July 2020)
* **Tooling:** Base R (Statistical Modeling, Residual Diagnostics, Exploratory Data Analysis)
* **Coursework:** ST3131 Regression Analysis (National University of Singapore)

---

## Modeling Methodology & Diagnostic Treatment

### 1. Baseline Model (M0)
* Fitted an initial multi-variable OLS regression on raw resale prices:
resale_price ~ town + flat_type + storey_range + floor_area_sqm + flat_model + lease_numeric
* **Baseline Fit:** Adjusted R² = 0.8775 | F = 284.7 (p < 2.2e-16)
* **Diagnostic Violations:**
  * **Heteroscedasticity:** Standardized residuals vs. fitted values exhibited a severe "funnel shape" with variance widening on higher-priced properties.
  * **Non-Normality:** Normal Q-Q plots showed significant heavy tails, violating fundamental OLS error distribution assumptions.

### 2. Variance-Stabilizing Treatment (M1)
* Applied a log-transformation to the response variable:
log(resale_price) ~ town + flat_type + storey_range + floor_area_sqm + flat_model + lease_numeric
* **Outcome:**
  * Collapsed residual fan patterns into a uniform, homoscedastic error band across fitted values.
  * Curbed tail departures on the normal Q-Q plot.
  * Reduced Residual Standard Error (RSE) to **0.1024** and lifted explained variance to **90.68%** (Adjusted R² = 0.9068).

---

## Key Findings & Economic Interpretations

| Metric / Attribute | Analytical Impact | Interpretation |
| :--- | :--- | :--- |
| **Model Fit (Adj. R²)** | **0.8775 -> 0.9068** | Log transformation captures non-linear compounding premiums. |
| **Residual Standard Error** | **0.1024** | Tight prediction bounds on percentage price movements. |
| **Floor Area (`floor_area_sqm`)** | **+0.88% per sqm** | Derived via (exp(0.0088) - 1) * 100; steady floor-space premium. |
| **Spatial Premium (`townBISHAN`)** | **+25.7% vs. baseline** | Derived via (exp(0.229) - 1) * 100 relative to Ang Mo Kio baseline. |
| **Primary Value Drivers** | `flat_type` & `lease_numeric` | Highest Mean Square variance contribution in ANOVA (p < 2.2e-16). |

---

## How to Run

1. Clone this repository:
bash
git clone https://github.com/angelode1eon/hdb-resale-price-prediction.git
cd hdb-resale-price-prediction
2. Run via CLI or RStudio:
Rscript scripts/ST3131_Report.R
