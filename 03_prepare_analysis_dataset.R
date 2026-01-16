# =============================================================================
# 03_prepare_analysis_dataset.R

#   This script prepares the final modelling dataset from the pooled,
#   harmonised Excel file. It does NOT perform questionnaire harmonisation
#   or BMI calculation. Those steps occur upstream.
#
# Data provenance:
#   The input file "pooled_harmonised_dataset.xlsx" is an assembled dataset
#   created as follows:
#
#   1) BMI z-scores (bmi_z) were calculated in R for all HBM-II children using
#      WHO growth references (see Script 02_bmi_zscores.R) and added to the
#      HBM-II dataset.
#
#   2) Fish consumption for HBM-II was harmonised via Monte Carlo simulation
#      across fish product types (see Script 01_fish_hbmii.R), producing
#      the variable "fish_new".
#
#   3) Fish consumption in PHIME, DEMOCOPHES, and CROME was harmonised manually
#      in Excel from their original questionnaires using the same three-level
#      classification (low / moderate / high), because those studies did not
#      require Monte Carlo reconstruction.
#
#   4) All four studies (PHIME, DEMOCOPHES, CROME, HBM-II) were then merged in
#      Excel into a single pooled dataset ("pooled_harmonised_dataset.xlsx")
#      containing:
#        - urinary Hg (ng/mL and µg/g creatinine)
#        - creatinine
#        - amalgam variables
#        - fish_new (harmonised)
#        - bmi_z (WHO standardised)
#        - age, sex, town, year, study
#
#
# Important: This script starts from that harmonised pooled dataset and constructs
#   analysis-ready variables (log transforms, centering, factors) and the
#   complete-case dataset used for modelling.
#
# Inputs (assumed already present in Excel):
#   - uhg_ngml, uhg_creat
#   - amalgam_yes_no, amalgam_num
#   - fish_new (already harmonised across studies; HBM-II produced separately; see 01_fish_new)
#   - age, sex, year, study, town_id, town_type
#   - bmi_z (produced in R separately; see 02_bmi_zscores.R)
#
# Outputs:
#   - dat      (analysis dataset with derived variables)
#   - dat_cc   (complete-case subset for sequential models)
# =============================================================================

rm(list = ls())

# -------------------- user settings / paths --------------------
# Change this to your local project folder
PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"

# Input pooled Excel dataset (harmonised)
INPUT_XLSX  <- file.path(PROJECT_DIR, "data", "pooled_harmonised_dataset.xlsx")
INPUT_SHEET <- 1      # default is the first sheet, to be adjusted accordingly

# -------------------- libraries --------------------
library(dplyr)
library(tidyr)
library(openxlsx)

options(scipen = 999)   # to present numeric values in a clear, readable format

# -------------------- Load data --------------------
dat <- openxlsx::read.xlsx(INPUT_XLSX, sheet = INPUT_SHEET)

# -------------------- Basic checks: required columns --------------------
required_cols <- c(
  "study", "age", "sex", "year",
  "town_id", "town_type",
  "uhg_ngml", "uhg_creat",
  "amalgam_yes_no", "amalgam_num",
  "fish_new",
  "bmi_z"
)

missing_cols <- setdiff(required_cols, names(dat))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# -------------------- Restrict HBM-II age range (6–9 y only) --------------------
dat <- dat %>%
  filter(!(study == "HBM-II" & (age < 6 | age > 9)))

# -------------------- Derive analysis variables --------------------
dat <- dat %>%
  mutate(
    
    ucreat_gL       = uhg_ngml / uhg_creat,
    ln_uhg_ngml = log(uhg_ngml),
    ln_ucreat_gL    = log(ucreat_gL),
    
    # ensure factors where necessary
    amalgam = factor(
      amalgam_yes_no,
      levels = c(2, 1),
      labels = c("No", "Yes")
    ),
    fish_new = factor(fish_new),  # low/medium/high (already harmonised)
    sex      = factor(sex),
    study    = factor(study, levels = c("PHIME", "DEMOCOPHES", "CROME", "HBM-II")),
    town     = factor(town_id),
    town_type = factor(
      town_type,
      levels = c("urban", "rural", "potentially contaminated")
    ),
    
    # Set amalgam_num = 0 for children without amalgams 
    amalgam_num = if_else(amalgam == "No", 0L, amalgam_num),
    
    # Centred covariates
    age_centered      = age - mean(age, na.rm = TRUE),
    ln_ucreat_gL_centered = ln_ucreat_gL - mean(ln_ucreat_gL, na.rm = TRUE),
    
    # Calendar year centered (numeric)
    year_c = as.numeric(scale(year, center = TRUE, scale = FALSE)),
    year_f = factor(year)    
  )

# Ensure year_c is a numeric vector 
if (is.matrix(dat$year_c)) dat$year_c <- dat$year_c[, 1]
dat$year_c <- as.numeric(dat$year_c)

# Centred amalgam_num for modelling
dat <- dat %>%
  mutate(
    amalgam_num_centered = amalgam_num - mean(amalgam_num, na.rm = TRUE)
  )

# -------------------- Define complete-case dataset --------------------
vars_for_cc <- c(
  "ln_uhg_ngml",         # outcome
  "year_c",              # time
  "fish_new",            # harmonized fish consumption
  "bmi_z",               # bmi z score already calculated
  "ln_ucreat_gL_centered",   # centered creatinine 
  "town_type",           # urban, rural, potentially contaminated
  "age_centered",        # age centered
  "sex",                 # male, female
  "town",                # actual town of residence
  "amalgam",               # yes, no
  "amalgam_num_centered"   # number of dental amalgams centred
)

dat_cc <- dat %>%
  filter(across(all_of(vars_for_cc), ~ !is.na(.)))

message("Total N = ", nrow(dat), " | Complete cases N = ", nrow(dat_cc))

# -------------------- (optional) save as RDS for the next scripts --------------------
# dir.create(file.path(PROJECT_DIR, "derived"), showWarnings = FALSE, recursive = TRUE)
# saveRDS(dat,    file.path(PROJECT_DIR, "derived", "analysis_dat.rds"))
# saveRDS(dat_cc, file.path(PROJECT_DIR, "derived", "analysis_dat_complete_cases.rds"))


