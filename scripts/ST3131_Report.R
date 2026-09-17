# ==============================================================================
# ST3131 STATISTICAL REPORT: HDB RESALE PRICE ANALYSIS
# ==============================================================================

# --- 1. INITIAL SETUP ---
# setwd("/Users/Angelopabo/Documents/YEAR2/Y2S2/ST3131/datasets")
data = read.csv('hdb-resale-July-2020.csv')

# --- 2. DATA PRE-PROCESSING & CLEANING ---
# Filter for useful data (Removing month, block, street_name, lease_commence_date)
data_cleaned = data[, -c(1,4,5,9)]

# Extract years and months from remaining_lease string using Base R
years_char  <- sub(" years.*", "", data_cleaned$remaining_lease)
months_char <- sub(".*years (\\d+) months", "\\1", data_cleaned$remaining_lease)

years  <- as.numeric(years_char)
months <- as.numeric(months_char)
months[is.na(months)] <- 0  # Handle cases with no months mentioned

# Create unified numeric lease column and drop character column
data_cleaned$lease_numeric <- years + (months / 12)
data_cleaned$remaining_lease <- NULL

# Convert categorical variables to factors
data_cleaned$town         <- as.factor(data_cleaned$town)
data_cleaned$flat_type    <- as.factor(data_cleaned$flat_type)
data_cleaned$storey_range <- as.factor(data_cleaned$storey_range)
data_cleaned$flat_model   <- as.factor(data_cleaned$flat_model)


# ==============================================================================
# PART 1: EXPLORATORY DATA ANALYSIS (EDA)
# ==============================================================================

# --- 1.1) QUANTITATIVE ANALYSIS: Floor Area & Lease ---
par(mfrow = c(2,2))

# Floor Area vs Price (Linearity/Variance Check)
plot(data_cleaned$floor_area_sqm, data_cleaned$resale_price, 
     main = 'Original Scale: Area vs Price', col = 'blue')
# Note: Clear positive relationship, but "funnel shape" indicates heteroscedasticity.

# Floor Area vs Log-Price (Transformation Check)
plot(data_cleaned$floor_area_sqm, log(data_cleaned$resale_price), 
     main = 'Log Scale: Area vs Price', col = 'red')
# Note: Log-transformation may be necessary to stabilize variance.

# Lease Numeric vs Price
plot(data_cleaned$lease_numeric, data_cleaned$resale_price, 
     main = 'Lease vs Price', col = 'green')
# Note: Positive association; newer flats (90+ years) dominate higher price brackets.

# --- 1.2) CATEGORICAL ANALYSIS: Flat Type & Storey ---
par(mfrow = c(1,2))

# Price by Flat Type
boxplot(resale_price ~ flat_type, data = data_cleaned, 
        main = "Price by Flat Type", las = 2, col = "orange")
# Note: Median price increases as flat type "improves" (more rooms).

# Price by Storey Range
boxplot(resale_price ~ storey_range, data = data_cleaned, 
        main = "Price by Storey Range", las = 2, col = "lightgreen")
# Note: General upward trend with storey height, though sample sizes are small at high levels.

table(data_cleaned$storey_range) # Verification of sample sizes


# ==============================================================================
# PART 2: INITIAL MODEL DEVELOPMENT (M0)
# ==============================================================================

m0 = lm(resale_price ~ ., data = data_cleaned)
summary(m0) 
# Results: Adj R-sq: 0.8775 | F-stat: 284.7 | p-value: < 2.2e-16

# --- M0 INTERPRETATION ---
# floor_area_sqm: +1 sqm results in +$3649.4 in price.
# flat_modelMaisonette: +$113,655 compared to 1-room baseline.

anova(m0)
# All 6 regressors are highly significant (p < 0.05).
# Importance order (by Mean Sq): 1. flat_type, 2. lease_numeric.


# ==============================================================================
# PART 3: MODEL ADEQUACY CHECKING (M0)
# ==============================================================================

SR0   <- rstandard(m0)
Fits0 <- fitted(m0)
par(mfrow = c(2,3))

# 3.1) Normality: QQ Plot
qqnorm(SR0, main = "M0: QQ Plot (Normality Check)")
qqline(SR0, col = "red")
# Note: Heavy tails observed; normality assumption violated.

# 3.2) Constant Variance: Residuals vs Fitted
plot(Fits0, SR0, main = "M0: SR0 vs Fitted", xlab = "Fitted Values")
abline(h = 0, lty = 2, col = "blue")
# Note: Distinct funnel shape; constant variance violated.

# 3.3) Regressor Adequacy: Area, Lease, Storey
plot(m0$model$floor_area_sqm, SR0, main = "M0: SR0 vs Area")
abline(h = 0, lty = 2, col = "blue")

plot(m0$model$lease_numeric, SR0, main = "M0: SR0 vs Lease")
abline(h = 0, lty = 2, col = "blue")

boxplot(m0$residuals ~ m0$model$storey_range, main = "M0: Res vs Storey", las = 2, col = "lightblue")
abline(h = 0, col = "red", lwd = 2)
# Note: Variance increases for higher floors and larger flats/leases.


# ==============================================================================
# PART 4: IMPROVED MODEL DEVELOPMENT (M1 - TREATMENT)
# ==============================================================================

# Treatment: Log-transformation of response to handle heteroscedasticity
m1 = lm(log(resale_price) ~ ., data = data_cleaned)
summary(m1)
# Results: Adj R-sq: 0.9068 (Increased from 0.8775 in m0) | RSE: 0.1024 (Low) | p-value: < 2.2e-16

# --- M1 INTERPRETATION (Log-Linear) ---
# floor_area_sqm: (exp(0.0088007)-1)*100 = +0.88% price increase per sqm.
# townBISHAN: (exp(0.229)-1)*100 = +25.7% price premium vs AMK baseline.

# Note: Singularities occurred for 'MULTI-GENERATION' due to perfect collinearity.
# Insignificant variables: Bedok, Serangoon, and several flat models.

anova(m1)
# F-value for lease_numeric (1596.31) and flat_type (2468.30) are
# significantly higher than those in M0.
# Log-transformation allowed the regressors to more effectively explain the variation in the response.

# In the log-scale model, M1, flat_type (25.90) and lease_numeric (16.75) have
# highest Mean Squares by a large margin.
# This aligns with Singapore's housing context, where the size/utility of the flat and the
# remaining tenure on a 99-year lease are the primary value drivers.

# All the p-values are < 2.2e^-16
# Six regressors remain highly statistically significant, confirming that model selection
# is robust and that each chosen attribute contributes meaningfully to the final prediction.

# ==============================================================================
# PART 5: FINAL MODEL ADEQUACY CHECKING (M1)
# ==============================================================================

SR1   <- rstandard(m1)
Fits1 <- fitted(m1)
par(mfrow = c(2,3))

# 5.1) Normality: QQ Plot
qqnorm(SR1, main = "M1: QQ Plot (Normality Check)")
qqline(SR1, col = "red")
# Note: Significant improvement in center of distribution; heavy tails reduced.

# 5.2) Constant Variance: Residuals vs Fitted
plot(Fits1, SR1, main = "M1: SR1 vs Fitted", xlab = "Fitted Values")
abline(h = 0, lty = 2, col = "blue")
# Note: Funnel shape collapsed into a uniform cloud. Constant variance satisfied.

# 5.3) Regressor Adequacy
plot(m1$model$floor_area_sqm, SR1, main = "M1: SR1 vs Area")
abline(h = 0, lty = 2, col = "blue")

plot(m1$model$lease_numeric, SR1, main = "M1: SR1 vs Lease")
abline(h = 0, lty = 2, col = "blue")

boxplot(m1$residuals ~ m1$model$storey_range, main = "M1: Res vs Storey", las = 2, col = "lightblue")
abline(h = 0, col = "red", lwd = 2)

# --- CONCLUSION ---
# Model 1 successfully treated the violations found in M0.
# The log-transformation stabilized variance and improved normality.
# With an Adjusted R-squared of 0.9068, Model 1 is adequate for predicting HDB prices.



