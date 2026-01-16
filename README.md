# Analysis of Trends in Urinary Mercury (Hg) Concentrations in Slovenian Children (2007–2024)

This repository contains the complete R analysis pipeline used for the paper:

> **“Human Biomonitoring in Support of the Minamata Convention: A Case of Phasing Out Dental Amalgam”**  
> *Environmental Health*

The analysis is based on pooled data from four human biomonitoring (HBM) studies conducted in Slovenia:
- PHIME  (2007)
- DEMOCOPHES  (2011-12)
- CROME  (2016)
- SLO-HBM-II  (2018-24)

The pipeline is fully reproducible and covers:
- harmonisation of fish consumption data  
- preparation of biomonitoring datasets  
- fitting of mixed-effects models  
- quantification of attenuation of the calendar-year effect in urinary mercury concentrations attributable to dental amalgams  

---

## Instructions

Before running any script:

1. Open **`R/config.R`**
2. Set the path to your local project directory:
   ```r
   PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"
---
  
**01 - Fish consumption harmonization**

Open **`R/01_fish_hbmii_montecarlo.R`**

Purpose:
 - harmonises HBM-II fish consumption frequency data
 - aggregates multiple fish types using Monte Carlo simulation

Output:
 - derived/hbmii_fish_harmonised.rds
 - derived/hbmii_fish_harmonised.xlsx

---

**02 - BMI Z-scores calculation (pooled dataset)**

Open **`R/02_bmi_zscores.R`**

Purpose:
 - computes BMI z-scores using age- and sex-standardisation
 - caculation is based on WHO growth references

Output:
 - derived BMI z-scores saved to derived/

---

**03 - Preparation of analysis dataset**

Open **`R/03_prepare_analysis_dataset.R`**

Purpose: 
 - merges harmonized fish data, BMI z-scores, and biomonitoring data

Key steps: 
 - variable recoding, factor harmonization, centring of covariates, log-transformations

Creates:
 - full analysis dataset
 - complete-case dataset (for CC models)

Outputs: 
 - derived/analysis_dat.rds
 - derived/analysis_dat_complete_cases.rds

---

**04 - Mixed-effects models (complete-case and multiple imputation)**

Open **`R/04_models_cc_mi.R`**

Purpose: 
 - Fits a sequential set of linear mixed-effects models with following predictors:
  - calendar year only
  - covariates
  - fish consumption
  - dental amalgams 

 - Follows with interaction models for investigating effect modification (time x fish consumption, time x amalgam presence (yes/no) and time x amalgam number)
 - Performs multiple imputation (MI) as a sensitivity analysis and fits the same models on MI dataset

Extracts:
 - fixed effects on the log scale
 - Wald confidence intervals
 - AIC(BIC
 - CC vs MI comparison for the year effect

Outputs:
 - outputs/cc_fixed_all.rds
 - outputs/mi_fixed_all.rds
 - outputs/aicbic_cc.rds
 - outputs/aicbic_mi.rds

---

**05 - Master coefficient tables**

Open **`R/05_tables_master_ciefficients.R`**

Purpose:
 - Produces complete coefficient tables for all models (complete case and multiple imputation)

Reports:
 - effects on log scale (β)
 - effects on multiplicative scale (RR = exp(β))
 - correct SE(RR) via the delta method
 - confidence intervals on the RR scale

Outputs:
 - outputs/tables/Coefficients_ALL_MODELS_CC.xlsx
 - outputs/tables/Coefficients_ALL_MODELS_MI.xlsx

---

**06 - Attenuation of the year effect**

Open **`R/06_attenuation_year_effect.R`**

Purpose:
 - quantifies attenuation of the calendar-year effect by addition of covariates/dental amalgams

Calculates:
 - percentage attenuation relative to the base model
 - variance components and intraclass correlation coefficients (ICC)
 - uses raw log-scale coefficients for attenuation calculations

Output:
 - attenuation tables in Excel
 - 

 ---

**07 & 08 - Plotting the time trends (overall and separately in Idrija and Ljubljana)**

Open **`R/07_plotting_overall_trends.R`** or **`R/07_plotting_town_trends.R`**

Purpose:
- visualize trends in urinary Hg concentrations over the years, in relation to percentage children with amalgam and percentage distribution of children across fish consumption categories 

Input: 
- derived/analysis_dat.rds
  
Output:
- outputs/figures/uHg_ngml_trend_percentages_national.svg
- outputs/figures/uHg_creat_trend_percentages_national.svg
- outputs/figures/uHg_ngml_trend_percentages_Idrija.svg
- outputs/figures/uHg_creat_trend_percentages_Idrija.svg
- outputs/figures/uHg_ngml_trend_percentages_Ljubljana.svg
- outputs/figures/uHg_creat_trend_percentages_Ljubljana.svg

Each figure overlays:
- urinary Hg distribution
  - median (points)
  - interquartile range (error bars)
- exposure indicators (percentages)
  - stacked bars for fish consumption categories
  - separate bars for amalgam prevalence
- dual y-axis
  - left: urinary Hg concentration
  - right: percentage of children
  
---

**09 - Summary statistics and descriptives**

Open **`R/09_summary statistics and descriptives.R`**

Purpose:
 - provide transparent reporting of data completeness (number and percentage of missing values for urinary Hg variables, amalgam presence/number, fish consumption, age, sex, BMI)
 - summarize distributions of urinary Hg biomarkers (descriptive stats for urinary Hg variables) 
 - describe key exposure variables and covariates used in modeling (descriptive stats for amalgams, fish consumption, age, sex, BMI)

Input: 
 - derived/analysis_dat.rds

Output:
 - outputs/tables/missing_data_y_year.xlsx
 - outputs/tables/data_completeness_by_study.xlsx
 - outputs/tables/summary_statistics_by_study.xlsx
 - outputs/tables/summary_statistics_by_study_and_year.xlsx

---

Prepared by: Adna Alilović Osolin

