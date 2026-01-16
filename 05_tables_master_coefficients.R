# =============================================================================
# 05_tables_master_coefficients.R
#
# PURPOSE
#   Produce full coefficient tables for ALL models:
#     m_00, m_0, m_1, m_2, m3_cat, m3_cat_int, m4_num, m5_num
#
#   For BOTH:
#     - Complete Case (CC)
#     - Multiple Imputation (MI)
#
#   On the correct scale:
#     - Log(beta)  (model scale)
#     - RR = exp(beta)
#     - SE(RR) via delta method
#     - CI on RR scale
#
# INPUTS (from Script 04)
#   outputs/cc_fixed_all.rds
#   outputs/mi_fixed_all.rds
#
# OUTPUTS
#   tables/Coefficients_ALL_MODELS_CC.xlsx
#   tables/Coefficients_ALL_MODELS_MI.xlsx
# =============================================================================

rm(list = ls())

PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"
OUTPUT_DIR  <- file.path(PROJECT_DIR, "outputs")
TABLE_DIR   <- file.path(OUTPUT_DIR, "tables")

dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

library(dplyr)
library(tidyr)
library(openxlsx)

options(scipen = 999)

# =============================================================================
# 1. LOAD MODEL OUTPUTS
# =============================================================================

cc_fixed_all <- readRDS(file.path(OUTPUT_DIR, "cc_fixed_all.rds"))
mi_fixed_all <- readRDS(file.path(OUTPUT_DIR, "mi_fixed_all.rds"))

all_models <- c("m_00","m_0","m_1","m_2","m3_cat","m3_cat_int","m4_num","m5_num")

# =============================================================================
# 2. HELPER FORMATTERS
# =============================================================================

fmt_rr_se <- function(rr, se, digits=3) {
  ifelse(is.na(rr), NA_character_,
         sprintf(paste0("%.",digits,"f (%.",digits,"f)"), rr, se))
}

fmt_p <- function(p) {
  ifelse(is.na(p), NA_character_,
         ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)))
}

# =============================================================================
# 3. COMPLETE-CASE MASTER TABLE
# =============================================================================

cc_master <- cc_fixed_all %>%
  filter(model %in% all_models) %>%
  mutate(
    RR      = exp(estimate_cc),
    RR_low  = exp(conf.low_cc),
    RR_high = exp(conf.high_cc),
    
    # delta method
    SE_RR   = RR * se_cc,
    
    RR_SE   = fmt_rr_se(RR, SE_RR),
    p_form  = fmt_p(p_cc)
  ) %>%
  select(
    model, term,
    estimate_cc, se_cc, conf.low_cc, conf.high_cc, p_cc,
    RR, SE_RR, RR_low, RR_high,
    RR_SE, p_form
  ) %>%
  arrange(match(model, all_models), term)

# wide display versions
cc_rr_wide <- cc_master %>%
  select(model, term, RR_SE) %>%
  pivot_wider(names_from = model, values_from = RR_SE)

cc_p_wide <- cc_master %>%
  select(model, term, p_form) %>%
  pivot_wider(names_from = model, values_from = p_form, names_prefix = "p_")

openxlsx::write.xlsx(
  list(
    "Long_CC"     = cc_master,
    "RR(SE)_CC"   = cc_rr_wide,
    "p_CC"       = cc_p_wide
  ),
  file = file.path(TABLE_DIR, "Coefficients_ALL_MODELS_CC.xlsx"),
  overwrite = TRUE
)

# =============================================================================
# 4. MULTIPLE-IMPUTATION MASTER TABLE
# =============================================================================

mi_master <- mi_fixed_all %>%
  filter(model %in% all_models) %>%
  mutate(
    RR      = exp(estimate_mi),
    RR_low  = exp(conf.low_mi),
    RR_high = exp(conf.high_mi),
    
    SE_RR   = RR * se_mi,
    
    RR_SE   = fmt_rr_se(RR, SE_RR),
    p_form  = fmt_p(p_mi)
  ) %>%
  select(
    model, term,
    estimate_mi, se_mi, conf.low_mi, conf.high_mi, p_mi,
    RR, SE_RR, RR_low, RR_high,
    RR_SE, p_form
  ) %>%
  arrange(match(model, all_models), term)

mi_rr_wide <- mi_master %>%
  select(model, term, RR_SE) %>%
  pivot_wider(names_from = model, values_from = RR_SE)

mi_p_wide <- mi_master %>%
  select(model, term, p_form) %>%
  pivot_wider(names_from = model, values_from = p_form, names_prefix = "p_")

openxlsx::write.xlsx(
  list(
    "Long_MI"     = mi_master,
    "RR(SE)_MI"   = mi_rr_wide,
    "p_MI"       = mi_p_wide
  ),
  file = file.path(TABLE_DIR, "Coefficients_ALL_MODELS_MI.xlsx"),
  overwrite = TRUE
)

message("ALL-MODEL coefficient tables saved (CC + MI).")
