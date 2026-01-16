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
  
01 - Fish consumption harmonization
1. Open **`R/01_fish_hbmii_montecarlo.R`**

Purpose
- Harmonises HBM-II fish consumption frequency data
- Aggregates multiple fish types using Monte Carlo simulation
Output:
- derived/hbmii_fish_harmonised.rds
- derived/hbmii_fish_harmonised.xlsx
