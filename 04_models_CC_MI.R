# =============================================================================
# 04_models_cc_mi.R
#
# PURPOSE
#   Fit the core mixed-effects models used in the manuscript:
#     A) Sequential complete-case (CC) models
#     B) Multiple-imputation (MI) models (sensitivity analysis)
#   and extract fixed effects + AIC/BIC needed downstream for tables/attenuation.
#
# IMPORTANT (pipeline consistency with 01–03)
#   - Script 03_prepare_analysis_dataset.R creates and saves:
#       derived/analysis_dat.rds
#       derived/analysis_dat_complete_cases.rds
#   - This script (04) reads those RDS files.
#   - Exponentiation, % change, attenuation tables, and formatted outputs are
#     handled in Script 05_tables_attenuation.R.
#
# INPUTS
#   derived/analysis_dat.rds
#   derived/analysis_dat_complete_cases.rds
#
# OUTPUTS (written to outputs/)
#   - cc_fixed_all.rds            (log-scale fixed effects, CC)
#   - mi_fixed_all.rds            (log-scale pooled fixed effects, MI)
#   - aicbic_cc.rds               (AIC/BIC, CC)
#   - aicbic_mi.rds               (mean AIC/BIC over imputations, MI)
#   - compare_year_logscale.rds   (CC vs MI year_c only; log scale)
#   - imp_mids.rds                (optional; MI object for reproducibility)
#
# NOTES
#   - Variables expected to exist (from Script 03):
#       ln_uhg_ngml
#       year_c, year_f
#       fish_new
#       bmi_z
#       ln_ucreat_gL_centered
#       town_type
#       age_centered
#       sex
#       town
#       study
#       amalgam (Yes/No)
#       amalgam_num
#       amalgam_num_centered
#
# =============================================================================

rm(list = ls())

# -------------------- Paths --------------------
PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"
DERIVED_DIR <- file.path(PROJECT_DIR, "derived")
OUTPUT_DIR  <- file.path(PROJECT_DIR, "outputs")

dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

# -------------------- Libraries --------------------
library(dplyr)
library(tidyr)
library(lme4)
library(lmerTest)
library(mice)
library(broom.mixed)
library(tibble)

options(scipen = 999)

# =============================================================================
# 0. LOAD PREPARED DATA (from Script 03)
# =============================================================================
dat    <- readRDS(file.path(DERIVED_DIR, "analysis_dat.rds"))
dat_cc <- readRDS(file.path(DERIVED_DIR, "analysis_dat_complete_cases.rds"))

# --- sanity checks: required columns for this script ---
required_cols_dat <- c(
  "ln_uhg_ngml",
  "year_c", "year_f",
  "fish_new",
  "bmi_z",
  "ln_ucreat_gL_centered",
  "town_type",
  "age_centered",
  "sex",
  "town",
  "study",
  "amalgam",
  "amalgam_num",
  "amalgam_num_centered"
)

missing_dat <- setdiff(required_cols_dat, names(dat))
missing_cc  <- setdiff(required_cols_dat, names(dat_cc))

if (length(missing_dat) > 0) stop("Missing in dat: ", paste(missing_dat, collapse = ", "))
if (length(missing_cc)  > 0) stop("Missing in dat_cc: ", paste(missing_cc, collapse = ", "))

message("Loaded dat (N = ", nrow(dat), ") and dat_cc (N = ", nrow(dat_cc), ").")

# =============================================================================
# 1. COMPLETE-CASE (CC) MODELS
# =============================================================================

# m_00: crude calendar-year trend
m_00 <- lmer(
  ln_uhg_ngml ~ year_c + (1 | town),
  data = dat_cc,
  REML = FALSE
)

# m_0: adjust for demographics, creatinine, BMI, town type
m_0 <- lmer(
  ln_uhg_ngml ~ year_c +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

# m_1: add fish
m_1 <- lmer(
  ln_uhg_ngml ~ year_c +
    fish_new +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

# m_2: add amalgam number
m_2 <- lmer(
  ln_uhg_ngml ~ year_c +
    amalgam_num_centered +
    fish_new +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

# Interaction models (effect modification)
m3_cat <- lmer(
  ln_uhg_ngml ~ year_c +
    amalgam +
    fish_new * year_c +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

m3_cat_int <- lmer(
  ln_uhg_ngml ~ year_c * amalgam +
    fish_new * year_c +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

m4_num <- lmer(
  ln_uhg_ngml ~ year_c +
    amalgam_num_centered +
    fish_new * year_c +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

m5_num <- lmer(
  ln_uhg_ngml ~ year_c * amalgam_num_centered +
    fish_new * year_c +
    bmi_z + ln_ucreat_gL_centered +
    town_type + age_centered + sex +
    (1 | town),
  data = dat_cc,
  REML = FALSE
)

# =============================================================================
# 2. EXTRACT CC FIXED EFFECTS (log scale, with Wald CI)
# =============================================================================

tidy_cc <- function(model, model_name) {
  broom.mixed::tidy(
    model,
    effects = "fixed",
    conf.int = TRUE,
    conf.method = "Wald"
  ) %>%
    transmute(
      model        = model_name,
      term         = term,
      estimate_cc  = estimate,
      se_cc        = std.error,
      conf.low_cc  = conf.low,
      conf.high_cc = conf.high,
      p_cc         = p.value
    )
}

cc_fixed_all <- bind_rows(
  tidy_cc(m_00,       "m_00"),
  tidy_cc(m_0,        "m_0"),
  tidy_cc(m_1,        "m_1"),
  tidy_cc(m_2,        "m_2"),
  tidy_cc(m3_cat,     "m3_cat"),
  tidy_cc(m3_cat_int, "m3_cat_int"),
  tidy_cc(m4_num,     "m4_num"),
  tidy_cc(m5_num,     "m5_num")
)

# AIC/BIC for CC models
aicbic_cc <- tibble(
  model = c("m_00","m_0","m_1","m_2","m3_cat","m3_cat_int","m4_num","m5_num"),
  AIC   = c(AIC(m_00), AIC(m_0), AIC(m_1), AIC(m_2), AIC(m3_cat), AIC(m3_cat_int), AIC(m4_num), AIC(m5_num)),
  BIC   = c(BIC(m_00), BIC(m_0), BIC(m_1), BIC(m_2), BIC(m3_cat), BIC(m3_cat_int), BIC(m4_num), BIC(m5_num))
)

# =============================================================================
# 3. MULTIPLE IMPUTATION (MI) SETUP (sensitivity analysis)
# =============================================================================
# Keep MI variables consistent with your original approach, but aligned to Script 03 names.

vars_mi <- c(
  "ln_uhg_ngml",
  "year_c",
  "fish_new",
  "bmi_z",
  "ln_ucreat_gL_centered",
  "town_type",
  "age_centered",
  "sex",
  "town",
  "study",
  "amalgam_num",
  "amalgam"
)

imp_data <- dat %>% dplyr::select(all_of(vars_mi))

# --- define imputation methods ---
meth <- make.method(imp_data)

# Categorical
meth["sex"]       <- "logreg"   # binary in your coding (factor)
meth["amalgam"]   <- "logreg"   # Yes/No
meth["fish_new"]  <- "polyreg"  # 3-level
meth["town_type"] <- "polyreg"  # 3-level

# Numeric (PMM is robust)
meth["amalgam_num"]          <- "pmm"
meth["ln_uhg_ngml"]          <- "pmm"
meth["bmi_z"]                <- "pmm"
meth["ln_ucreat_gL_centered"]<- "pmm"
meth["year_c"]               <- "pmm"
meth["age_centered"]         <- "pmm"

# Grouping IDs not imputed
meth["town"]  <- ""
meth["study"] <- ""

# --- predictor matrix ---
pred <- make.predictorMatrix(imp_data)

# Do not impute town/study; also do not use them as outcomes
pred["town", ]  <- 0
pred["study", ] <- 0

# NOTE: town and study can still be predictors for others (default is OK),
# because we only set their rows to 0 (not their columns).

# --- run MI ---
set.seed(123)
imp <- mice(
  imp_data,
  m               = 20,
  method          = meth,
  predictorMatrix = pred,
  seed            = 123
)

# =============================================================================
# 4. FIT MODELS ON MI DATA (same model set as CC)
# =============================================================================

# helper: fit lmer inside with(), ensuring amalgam_num_centered exists per completed dataset
fit_mi_model <- function(imp_obj, formula_str) {
  with(
    imp_obj,
    {
      amalgam_num_centered <- amalgam_num - mean(amalgam_num, na.rm = TRUE)
      lmer(as.formula(formula_str), REML = FALSE)
    }
  )
}

# sequential MI models
fit_mi_00 <- fit_mi_model(imp, "ln_uhg_ngml ~ year_c + (1 | town)")

fit_mi_0  <- fit_mi_model(
  imp,
  "ln_uhg_ngml ~ year_c +
     bmi_z + ln_ucreat_gL_centered +
     town_type + age_centered + sex +
     (1 | town)"
)

fit_mi_1  <- fit_mi_model(
  imp,
  "ln_uhg_ngml ~ year_c +
     fish_new +
     bmi_z + ln_ucreat_gL_centered +
     town_type + age_centered + sex +
     (1 | town)"
)

fit_mi_2  <- fit_mi_model(
  imp,
  "ln_uhg_ngml ~ year_c +
     amalgam_num_centered +
     fish_new +
     bmi_z + ln_ucreat_gL_centered +
     town_type + age_centered + sex +
     (1 | town)"
)

# interaction models (match CC definitions)
fit_mi3_cat <- with(
  imp,
  lmer(
    ln_uhg_ngml ~ year_c +
      amalgam +
      fish_new * year_c +
      bmi_z + ln_ucreat_gL_centered +
      town_type + age_centered + sex +
      (1 | town),
    REML = FALSE
  )
)

fit_mi3_cat_int <- with(
  imp,
  lmer(
    ln_uhg_ngml ~ year_c * amalgam +
      fish_new * year_c +
      bmi_z + ln_ucreat_gL_centered +
      town_type + age_centered + sex +
      (1 | town),
    REML = FALSE
  )
)

fit_mi4_num <- fit_mi_model(
  imp,
  "ln_uhg_ngml ~ year_c +
     amalgam_num_centered +
     fish_new * year_c +
     bmi_z + ln_ucreat_gL_centered +
     town_type + age_centered + sex +
     (1 | town)"
)

fit_mi5_num <- fit_mi_model(
  imp,
  "ln_uhg_ngml ~ year_c * amalgam_num_centered +
     fish_new * year_c +
     bmi_z + ln_ucreat_gL_centered +
     town_type + age_centered + sex +
     (1 | town)"
)

# =============================================================================
# 5. POOL MI FIXED EFFECTS (log scale)
# =============================================================================

tidy_mi <- function(with_fit, model_name) {
  pool(with_fit) %>%
    summary(conf.int = TRUE, conf.level = 0.95) %>%
    transmute(
      model        = model_name,
      term         = term,
      estimate_mi  = estimate,
      se_mi        = std.error,
      conf.low_mi  = `2.5 %`,
      conf.high_mi = `97.5 %`,
      p_mi         = p.value
    )
}

mi_fixed_all <- bind_rows(
  tidy_mi(fit_mi_00,       "m_00"),
  tidy_mi(fit_mi_0,        "m_0"),
  tidy_mi(fit_mi_1,        "m_1"),
  tidy_mi(fit_mi_2,        "m_2"),
  tidy_mi(fit_mi3_cat,     "m3_cat"),
  tidy_mi(fit_mi3_cat_int, "m3_cat_int"),
  tidy_mi(fit_mi4_num,     "m4_num"),
  tidy_mi(fit_mi5_num,     "m5_num")
)

# =============================================================================
# 6. AIC/BIC FOR MI (mean across imputations)
# =============================================================================

get_aic_bic_mean <- function(with_obj) {
  mats <- t(sapply(with_obj$analyses, function(m) c(AIC = AIC(m), BIC = BIC(m))))
  tibble(
    AIC_mean = mean(mats[, "AIC"]),
    BIC_mean = mean(mats[, "BIC"])
  )
}

aicbic_mi <- bind_rows(
  tibble(model = "m_00")       %>% bind_cols(get_aic_bic_mean(fit_mi_00)),
  tibble(model = "m_0")        %>% bind_cols(get_aic_bic_mean(fit_mi_0)),
  tibble(model = "m_1")        %>% bind_cols(get_aic_bic_mean(fit_mi_1)),
  tibble(model = "m_2")        %>% bind_cols(get_aic_bic_mean(fit_mi_2)),
  tibble(model = "m3_cat")     %>% bind_cols(get_aic_bic_mean(fit_mi3_cat)),
  tibble(model = "m3_cat_int") %>% bind_cols(get_aic_bic_mean(fit_mi3_cat_int)),
  tibble(model = "m4_num")     %>% bind_cols(get_aic_bic_mean(fit_mi4_num)),
  tibble(model = "m5_num")     %>% bind_cols(get_aic_bic_mean(fit_mi5_num))
)

# =============================================================================
# 7. CC vs MI QUICK CHECK (LOG SCALE) – YEAR EFFECT ONLY
# =============================================================================
cc_year_log <- cc_fixed_all %>%
  filter(term == "year_c") %>%
  select(model, term, estimate_cc, se_cc, conf.low_cc, conf.high_cc, p_cc)

mi_year_log <- mi_fixed_all %>%
  filter(term == "year_c") %>%
  select(model, term, estimate_mi, se_mi, conf.low_mi, conf.high_mi, p_mi)

compare_year_logscale <- full_join(cc_year_log, mi_year_log, by = c("model","term")) %>%
  arrange(match(model, c("m_00","m_0","m_1","m_2","m3_cat","m3_cat_int","m4_num","m5_num")))

# =============================================================================
# 8. SAVE OUTPUTS FOR SCRIPT 05
# =============================================================================

saveRDS(cc_fixed_all,            file.path(OUTPUT_DIR, "cc_fixed_all.rds"))
saveRDS(mi_fixed_all,            file.path(OUTPUT_DIR, "mi_fixed_all.rds"))
saveRDS(aicbic_cc,               file.path(OUTPUT_DIR, "aicbic_cc.rds"))
saveRDS(aicbic_mi,               file.path(OUTPUT_DIR, "aicbic_mi.rds"))
saveRDS(compare_year_logscale,   file.path(OUTPUT_DIR, "compare_year_logscale.rds"))

# Optional: save MI object for full reproducibility (can be large)
saveRDS(imp, file.path(OUTPUT_DIR, "imp_mids.rds"))

message("04_models_cc_mi.R finished.")
message("Outputs saved to: ", OUTPUT_DIR)
