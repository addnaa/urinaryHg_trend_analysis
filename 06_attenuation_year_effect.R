# =============================================================================
# 06_attenuation_year_effect.R
#
# PURPOSE
#   Quantify attenuation of the calendar-year effect (year_c) across sequential
#   models, especially the drop in the year trend after adding amalgam number.
#
#   We compute attenuation using the RAW year_c coefficient (beta on log scale),
#   because attenuation is defined on the model coefficient scale.
#
#   Models (sequential):
#     m_00 -> m_0 -> m_1 -> m_2
#
#   Outputs both CC and MI attenuation results.
#
# INPUTS (from Script 04)
#   outputs/cc_fixed_all.rds
#   outputs/mi_fixed_all.rds
#
# OUTPUTS
#   outputs/tables/Attenuation_YearEffect_CC_MI.xlsx
# =============================================================================

rm(list = ls())

PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"
OUTPUT_DIR  <- file.path(PROJECT_DIR, "outputs")
TABLE_DIR   <- file.path(OUTPUT_DIR, "tables")
dir.create(TABLE_DIR, showWarnings = FALSE, recursive = TRUE)

library(dplyr)
library(openxlsx)

options(scipen = 999)

# =============================================================================
# 1. LOAD FIXED EFFECTS (log scale)
# =============================================================================

cc_fixed_all <- readRDS(file.path(OUTPUT_DIR, "cc_fixed_all.rds"))
mi_fixed_all <- readRDS(file.path(OUTPUT_DIR, "mi_fixed_all.rds"))

seq_models <- c("m_00","m_0","m_1","m_2")

# =============================================================================
# 2. Helper: extract year_c row + compute RR per year (optional)
# =============================================================================

extract_year <- function(df, which_scale = c("cc","mi")) {
  which_scale <- match.arg(which_scale)
  
  if (which_scale == "cc") {
    out <- df %>%
      filter(model %in% seq_models, term == "year_c") %>%
      transmute(
        model,
        beta = estimate_cc,
        se   = se_cc,
        lo   = conf.low_cc,
        hi   = conf.high_cc,
        p    = p_cc
      )
  } else {
    out <- df %>%
      filter(model %in% seq_models, term == "year_c") %>%
      transmute(
        model,
        beta = estimate_mi,
        se   = se_mi,
        lo   = conf.low_mi,
        hi   = conf.high_mi,
        p    = p_mi
      )
  }
  
  # Add RR scale interpretation (per +1 year_c unit; year_c is centered year)
  out %>%
    mutate(
      RR      = exp(beta),
      RR_low  = exp(lo),
      RR_high = exp(hi),
      pct     = (RR - 1) * 100
    ) %>%
    arrange(match(model, seq_models))
}

cc_year <- extract_year(cc_fixed_all, "cc")
mi_year <- extract_year(mi_fixed_all, "mi")

# =============================================================================
# 3. Attenuation function (on beta scale)
# =============================================================================
# Attenuation from baseline beta0 to beta1:
#   attenuation(%) = 100 * (1 - |beta1| / |beta0|)
#
# Note:
# - using absolute value is standard when you care about magnitude reduction
#   regardless of sign. If you want signed attenuation, drop abs().
# - if beta0 is ~0, attenuation is unstable; we guard against division by ~0.

attenuate <- function(beta0, beta1) {
  if (is.na(beta0) || is.na(beta1)) return(NA_real_)
  if (abs(beta0) < 1e-12) return(NA_real_)
  100 * (1 - abs(beta1) / abs(beta0))
}

compute_atten_table <- function(year_df) {
  
  beta_m00 <- year_df$beta[year_df$model == "m_00"]
  beta_m0  <- year_df$beta[year_df$model == "m_0"]
  beta_m1  <- year_df$beta[year_df$model == "m_1"]
  beta_m2  <- year_df$beta[year_df$model == "m_2"]
  
  tibble::tibble(
    comparison = c(
      "m_00 → m_0 (basic adjustment)",
      "m_0 → m_1 (+ fish)",
      "m_1 → m_2 (+ amalgam number)",
      "m_00 → m_2 (overall)"
    ),
    attenuation_pct = c(
      attenuate(beta_m00, beta_m0),
      attenuate(beta_m0,  beta_m1),
      attenuate(beta_m1,  beta_m2),
      attenuate(beta_m00, beta_m2)
    )
  )
}

cc_atten <- compute_atten_table(cc_year)
mi_atten <- compute_atten_table(mi_year)

# =============================================================================
# 4. Export
# =============================================================================

openxlsx::write.xlsx(
  list(
    "YearEffect_CC_log+RR" = cc_year,
    "YearEffect_MI_log+RR" = mi_year,
    "Attenuation_CC"       = cc_atten,
    "Attenuation_MI"       = mi_atten
  ),
  file = file.path(TABLE_DIR, "Attenuation_YearEffect_CC_MI.xlsx"),
  overwrite = TRUE
)

message("Attenuation tables saved to: ", file.path(TABLE_DIR, "Attenuation_YearEffect_CC_MI.xlsx"))
