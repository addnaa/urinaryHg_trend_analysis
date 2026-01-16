############################################################
# 02_bmi_zscores.R
#
# Purpose:
#   Calculate BMI-for-age z-scores (WHO reference)
#   using weight, height, sex, and age.
#
# Input:
#   data/pooled_hbm_raw.xlsx       = pooled dataset with BMI as it is
#
# Output:
#   derived/pooled_with_bmiz.rds   = pooled dataset with additionally calculated BMI z-scores
#   derived/pooled_with_bmiz.xlsx
############################################################

rm(list = ls())

## ==========================
## 0. Load libraries
## ==========================
library(openxlsx)
library(dplyr)
library(zscorer)

## ==========================
## 1. Paths
## ==========================
source("R/config.R")   # defines INPUT_DIR and DERIVED_DIR

## ==========================
## 2. Read raw pooled dataset
## ==========================
data <- read.xlsx(
  file.path(INPUT_DIR, "pooled_hbm_raw.xlsx"),
  sheet = 1
)

## ==========================
## 3. Prepare age and BMI
## ==========================

# Convert age (years) → months → days (WHO requires days)
data <- data %>%
  mutate(
    age_months = age * 12,
    age_days   = age_months * (365.25 / 12),
    
    # Raw BMI (kg/m^2) for checks
    bmi = weight / ( (height / 100)^2 )
  )

## ==========================
## 4. Calculate BMI-for-age z-scores (WHO)
## ==========================

# sex: 1 = male, 2 = female
data <- addWGSR(
  data       = data,
  sex        = "sex",
  firstPart  = "weight",
  secondPart = "height",
  thirdPart  = "age_days",
  index      = "bfa",       # BMI-for-age
  output     = "bmi_z",
  digits     = 3
)

## ==========================
## 5. Quality check
## ==========================
summary(data$bmi_z)

## ==========================
## 6. Save outputs
## ==========================

saveRDS(
  data,
  file.path(DERIVED_DIR, "pooled_with_bmiz.rds")
)

write.xlsx(
  data,
  file.path(DERIVED_DIR, "pooled_with_bmiz.xlsx"),
  overwrite = TRUE
)

cat("BMI z-scores calculated and saved.\n")
