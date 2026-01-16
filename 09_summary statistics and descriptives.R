###############################################################################
## 00_summary_statistics_and_descriptives.R
## Summary statistics and missing data reporting
###############################################################################

rm(list = ls())
options(scipen = 999)

library(dplyr)
library(tidyr)
library(openxlsx)
library(writexl)
library(DescTools)

# =============================================================================
# 0. LOAD DATA
# =============================================================================
source("R/config.R")

data <- readRDS(
  file.path(DERIVED_DIR, "analysis_dat.rds")
)

# HBM-II: restrict to children aged 6–9
data <- data %>%
  filter(!(study == "HBM-II" & (age < 6 | age > 9)))

# Enforce study order
study_order <- c("PHIME", "DEMOCOPHES", "CROME", "HBM-II")
data <- data %>%
  mutate(study = factor(study, levels = study_order))

# =============================================================================
# 1. HELPER FUNCTIONS
# =============================================================================

geo_mean <- function(x) {
  x <- x[x > 0 & !is.na(x)]
  if (length(x) == 0) return(NA_real_)
  exp(mean(log(x)))
}

hg_summary <- function(x) {
  tibble(
    GM  = round(geo_mean(x), 3),
    P5  = round(quantile(x, 0.05, na.rm = TRUE), 3),
    P25 = round(quantile(x, 0.25, na.rm = TRUE), 3),
    P50 = round(quantile(x, 0.50, na.rm = TRUE), 3),
    P75 = round(quantile(x, 0.75, na.rm = TRUE), 3),
    P90 = round(quantile(x, 0.90, na.rm = TRUE), 3),
    P95 = round(quantile(x, 0.95, na.rm = TRUE), 3)
  )
}

# =============================================================================
# 2. MISSING DATA SUMMARY (TRANSPARENT & CENTRALIZED)
# =============================================================================

vars_key <- c(
  "uhg_ngml",
  "uhg_creat",
  "amalgam_yes_no",
  "fish_new",
  "age",
  "bmi",
  "sex"
)

missing_summary <- data %>%
  group_by(study, year) %>%
  summarise(
    N_total = n(),
    across(
      all_of(vars_key),
      ~ sum(is.na(.)),
      .names = "missing_{.col}"
    ),
    across(
      all_of(vars_key),
      ~ round(100 * mean(is.na(.)), 1),
      .names = "missing_pct_{.col}"
    ),
    .groups = "drop"
  )

write_xlsx(
  missing_summary,
  "missing_summary_by_study_year.xlsx"
)

# =============================================================================
# 3. POPULATION CHARACTERISTICS
# =============================================================================

population_summary <- data %>%
  group_by(study) %>%
  summarise(
    N = n(),
    Mean_age   = round(mean(age, na.rm = TRUE), 1),
    SD_age     = round(sd(age, na.rm = TRUE), 1),
    Median_age = round(median(age, na.rm = TRUE), 1),
    IQR_age    = round(IQR(age, na.rm = TRUE), 1),
    Pct_male   = round(100 * mean(sex == 1, na.rm = TRUE), 1),
    Mean_bmi   = round(mean(bmi, na.rm = TRUE), 1),
    SD_bmi     = round(sd(bmi, na.rm = TRUE), 2),
    .groups = "drop"
  )

write_xlsx(
  population_summary,
  "population_characteristics_by_study.xlsx"
)

# =============================================================================
# 4. URINARY MERCURY SUMMARY (ng/mL & µg/g creatinine)
# =============================================================================

hg_summary_by_study_year <- data %>%
  group_by(study, year) %>%
  summarise(
    N_uhg_ngml  = sum(!is.na(uhg_ngml)),
    N_uhg_creat = sum(!is.na(uhg_creat)),
    uhg_ngml  = list(hg_summary(uhg_ngml)),
    uhg_creat = list(hg_summary(uhg_creat)),
    .groups = "drop"
  ) %>%
  unnest(c(uhg_ngml, uhg_creat), names_sep = "_")

write_xlsx(
  hg_summary_by_study_year,
  "urinary_hg_summary_by_study_year.xlsx"
)

# =============================================================================
# 5. EXPOSURE COVARIATES: AMALGAMS & FISH CONSUMPTION
# =============================================================================

exposure_summary <- data %>%
  group_by(study, year) %>%
  summarise(
    # --- Amalgams ---
    Pct_amalgam_yes = round(
      100 * mean(amalgam_yes_no == 1, na.rm = TRUE), 1
    ),
    Mean_amalgam_num = round(
      mean(amalgam_num[amalgam_yes_no == 1], na.rm = TRUE), 2
    ),
    SD_amalgam_num = round(
      sd(amalgam_num[amalgam_yes_no == 1], na.rm = TRUE), 2
    ),
    
    # --- Fish consumption (among non-missing) ---
    Fish_n_nonmiss = sum(!is.na(fish_new)),
    Fish_A_n = sum(fish_new == "A", na.rm = TRUE),
    Fish_B_n = sum(fish_new == "B", na.rm = TRUE),
    Fish_C_n = sum(fish_new == "C", na.rm = TRUE),
    
    Fish_A_pct = round(100 * mean(fish_new == "A", na.rm = TRUE), 1),
    Fish_B_pct = round(100 * mean(fish_new == "B", na.rm = TRUE), 1),
    Fish_C_pct = round(100 * mean(fish_new == "C", na.rm = TRUE), 1),
    
    Fish_missing_n   = sum(is.na(fish_new)),
    Fish_missing_pct = round(100 * mean(is.na(fish_new)), 1),
    
    .groups = "drop"
  )

write_xlsx(
  exposure_summary,
  "exposure_covariates_by_study_year.xlsx"
)


