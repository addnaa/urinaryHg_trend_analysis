# Codebook: Pooled urinary mercury dataset (children, Slovenia)

## 1. Dataset overview

This codebook describes the final analytical dataset (`analysis_dat`) used for statistical modelling, summary statistics, and data visualisation of urinary mercury concentrations in Slovenian children aged 6–9 years.

The dataset pools harmonised data from four human biomonitoring studies conducted between 2007 and 2024:

- PHIME  
- DEMOCOPHES  
- CROME  
- SLO-HBM-II  

Only variables required for analysis and interpretation are included.

---

## 2. Study identifiers

| Variable   | Description |
|------------|-------------|
| `study`    | Contributing biomonitoring study (PHIME, DEMOCOPHES, CROME, SLO-HBM-II) |
| `year`     | Calendar year of biological sampling |
| `town_id`  | Sampling town or study area |
| `town_type`| Area type (urban, rural, historically contaminated) |

---

## 3. Outcome variables (urinary mercury)

| Variable        | Description                              | Unit |
|-----------------|------------------------------------------|------|
| `uhg_ngml`      | Urinary mercury concentration            | ng mL⁻¹ |
| `uhg_creat`     | Creatinine-adjusted urinary mercury      | µg g⁻¹ creatinine |
| `ln_uhg_ngml`   | Natural log of urinary mercury            | log(ng mL⁻¹) |

Urinary mercury concentrations were log-transformed prior to modelling due to right-skewed distributions.

---

## 4. Exposure variables (dental amalgams)

| Variable        | Description                           | Coding |
|-----------------|---------------------------------------|--------|
| `amalgam`       | Presence of dental amalgam fillings   | Yes / No |
| `amalgam_num`   | Number of dental amalgam fillings     | Integer |

---

## 5. Harmonised fish consumption

| Variable    | Description                                 | Categories |
|-------------|---------------------------------------------|------------|
| `fish_new`  | Harmonised total fish consumption frequency | A: <1/month, B: 1–3/month, C: >3/month |

Fish consumption was harmonised across studies using rule-based recoding (PHIME, DEMOCOPHES, CROME) and Monte-Carlo simulation for SLO-HBM-II, where multiple fish types were assessed separately.

Full implementation is documented in **Script 01**.

---

## 6. Covariates

| Variable        | Description                     | Unit |
|-----------------|---------------------------------|------|
| `age`           | Age at sampling                 | years |
| `sex`           | Biological sex                  | male / female |
| `bmi`           | Body mass index                 | kg m⁻² |
| `bmi_z`         | WHO BMI-for-age z-score         | SD units |
| `u_creat_gL`    | Urinary creatinine concentration| g L⁻¹ |

BMI z-scores were computed using WHO growth references (see Script 02).

---

## 7. Derived and transformed variables

Several variables were transformed or centered prior to modelling to improve interpretability and numerical stability.

| Variable            | Description |
|---------------------|-------------|
| `year_c`            | Calendar year centered at the sample mean |
| `ln_ucreat_gL`      | Natural log of urinary creatinine |
| `ln_ucreat_gL_c`    | Centered log-creatinine |

---

## 8. Missing data

Missing data were primarily present in the PHIME study, while the remaining studies had near-complete information.

Primary analyses were conducted using complete-case datasets. Multiple imputation was used as a sensitivity analysis.

---

## 9. Related analysis scripts

- `01_fish_hbmii_montecarlo.R` - Fish consumption harmonisation  
- `02_bmi_z_calculation.R` - BMI z-score calculation  
- `03_prepare_analysis_dataset.R` - Final analytical dataset creation  
- `04_models_cc_mi.R` - Mixed-effects models (complete-case and MI)  
- `05_tables_master_coefficients.R` - Master coefficient tables  
- `06_attenuation_year_effect.R` - Attenuation analysis of year effects
- `07_plotting_overall_trends.R` - Plotting the overall time trends in urinary Hg across the pooled dataset
- `08_plotting_town_trends.R` - Plotting the time trends in urinary Hg in Idrija and Ljubljana
- `09_summary_statistics_and_descriptives.R`- Summary statistics and data completeness overview

---

*This codebook accompanies the pooled Slovenian human biomonitoring dataset used in the PhD thesis and associated publications.*
