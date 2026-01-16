# Analysis of trends in urinary Hg concentrations in Slovenian children, from 2007 until 2024, based on data from 4 HBM studies (PHIME, DEMOCOPHES, CROME, SLO-HBM-II). 
The repository contains scripts used for data analysis and visualization for the paper "Human Biomonitoring in the Support of Minamata Convention: A case of Phasing out Dental Amalgam", published in Environmental Health.
It contains a fully reproducible R analysis pipeline used to harmonise fish consumption data, prepare biomonitoring datasets, fit mixed-effects models, and quantify attenuation of calendar year effect in urinary mercury concentrations by dental amalgams.
# Instructions
Before running any script, open R/config.R and ste the path to your project: PROJECT_DIR <- "PATH/TO/YOUR/PROJECT". All input, derived, and output directories are defined relative to this path.
The analysis is organised into 6 sequential scripts. They should be run in numerical order.
01 - Fish Consumption Harmonization (HBM-II data only)
  01_fish_hbmii_montecarlo.R
    Harmonises HBM-II fish consumption frequency data
    Uses Monte Carlo simulation to aggregate multiple fish types
    Produces a three-level fish consumption variable:
      A: < 1 meal/month
      B: 1–3 meals/month
      C: > 3 meals/month
    Outputs: 
      derived/hbmii_fish_harmonised.rds
      derived/hbmii_fish_harmonised.xlsx

02 - BMI z-score calculation (for the pooled dataset)
   02_bmi_z_calculation.R

    Computes BMI z-scores using age- and sex-standardisation (based on WHO)
    Implemented fully in R for transparency and reproducibility
    Outputs:
       Derived BMI z-score variables saved to derived/

03 - Prepare Analysis Dataset
   03_prepare_analysis_dataset.R
    Merges harmonised fish data, BMI z-scores, and biomonitoring data
    Performs:
      Variable recoding
      Factor harmonisation
      Centering of covariates
      Log-transformations
    Creates:
      Full analysis dataset
      Complete-case dataset (for CC models)
     Outputs:
      derived/analysis_dat.rds
      derived/analysis_dat_complete_cases.rds

04 - Mixed-Effects Models (CC + MI)
  04_models_cc_mi.R
    Fits a sequential set of linear mixed-effects models:
      Calendar year only
      covariates
      fish consumption
      dental amalgams
      includes interaction models (effect modification)
      performs multiple imputation (MI) as a sensitivity analysis
    Extracts:
      Fixed effects on the log scale
      Wald confidence intervals
      AIC / BIC
      CC vs MI comparison for year effect
    Outputs:
      outputs/cc_fixed_all.rds 
      outputs/mi_fixed_all.rds
      outputs/aicbic_cc.rds
      outputs/aicbic_mi.rds

05 - Master Coefficient Tables
  05_tables_master_coefficients.R
    Produces complete coefficient tables for all models:
      Complete case (CC)
      Multiple imputation (MI)
    Reports effects on:
      Log scale (β)
      Multiplicative scale (RR = exp(β))
      Correct SE(RR) via delta method
      Confidence intervals on the RR scale
      Outputs both long-format and wide-format Excel tables
    Outputs:
      outputs/tables/Coefficients_ALL_MODELS_CC.xlsx
      outputs/tables/Coefficients_ALL_MODELS_MI.xlsx

06 - Attenuation of Calendar-Year Effect
  06_attenuation_year_effect.R
    Quantifies attenuation of the calendar-year effect across models
    Calculates:
      % attenuation relative to the base model
      Variance components and ICC
      Uses raw log-scale coefficients for attenuation calculations
      Outputs publication-ready tables
    Outputs:
      Attenuation tables (Excel)


  
