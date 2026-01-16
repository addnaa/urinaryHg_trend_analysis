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
- Harmonisation of fish consumption data  
- Preparation of biomonitoring datasets  
- Fitting of mixed-effects models  
- Quantification of attenuation of the calendar-year effect in urinary mercury concentrations attributable to dental amalgams  

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
- Harmonises HBM-II fish consumption frequency data
- Aggregates multiple fish types using Monte Carlo simulation

Output:
- derived/hbmii_fish_harmonised.rds
- derived/hbmii_fish_harmonised.xlsx

**02 - BMI Z-scores calculation (pooled dataset)**

Open **`R/02_bmi_zscores.R`**

Purpose:
- Computes BMI z-scores using age- and sex-standardisation
- Based on WHO growth references

Output:
- Derived BMI z-scores saved to derived/

**03 - Preparation of analysis dataset**

Open **`R/03_prepare_analysis_dataset.R`**

Purpose: 
- Merges harmonized fish data, BMI z-scores, and biomonitoring data

Key steps: 
- variable recoding, factor harmonization, centring of covariates, log-transformations

Creates:
- full analysis dataset
- complete-case dataset (for CC models)

Outputs: 
- derived/analysis_dat.rds
- derived/analysis_dat_complete_cases.rds

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
- Fixed effects on the log scale
- Wald confidence intervals
- AIC(BIC
- CC vs MI comparison for the year effect

Outputs:
- outputs/cc_fixed_all.rds
- outputs/mi_fixed_all.rds
- outputs/aicbic_cc.rds
- outputs/aicbic_mi.rds
