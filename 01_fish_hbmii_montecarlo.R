############################################################
# 01_fish_hbmii_montecarlo.R
#
# Purpose:
#   Harmonise HBM-II fish consumption data into a
#   three-level variable (A, B, C) using Monte-Carlo
#   simulation across fish types. The initial dataset
#   had consumption divided by fish type, and in 8 levels of consumption.
#
# Wanted categories:
#   A = <1 meal / month
#   B = 1–3 meals / month
#   C = >3 meals / month
#
# Input:
#   data/hbmii_fish_raw.xlsx    = HBM-II dataset with fish categories as they are (8 levels of consumption from never to multiple/day)
#
# Output:
#   derived/hbmii_fish_harmonised.xlsx    = HBM-II dataset with new fish categories
#   derived/hbmii_fish_harmonised.rds
############################################################

rm(list = ls())

## ==========================
## 0. Libraries
## ==========================
library(openxlsx)
library(dplyr)
library(purrr)
library(tibble)

## ==========================
## 1. Paths
## ==========================
source("R/config.R")

## ==========================
## 2. Read HBM-II fish data
## ==========================
dat <- read.xlsx(                            
  file.path(INPUT_DIR, "hbmii_fish_raw.xlsx"),            # Path to the directory where data is needs to be entered (INPUT_DIR)
  sheet = 1
)

fish_vars <- c("sea_fish", "river_fish", "frozen_fish", "canned_fish")

## ==========================
## 3. Quality control
## ==========================
# valid codes are 1–8
invalid_rows <- dat %>%
  filter(if_any(all_of(fish_vars), ~ !is.na(.) & !. %in% 1:8))

if (nrow(invalid_rows) > 0) {
  stop("Invalid fish frequency codes detected (must be 1–8).")
}

## ==========================
## 4. Map frequency codes → monthly intervals
## ==========================
freq_intervals <- tibble(
  code  = 1:8,
  min_m = c(0, 0, 1, 4, 8, 20, 28, 31),
  max_m = c(0, 1, 3, 4, 16, 24, 31, 60)
)

## ==========================
## 5. Monte-Carlo function
## ==========================
simulate_category <- function(sea, river, frozen, canned, n_sim = 5000) {
  
  if (any(is.na(c(sea, river, frozen, canned)))) {
    return(list(cat = NA, pA = NA, pB = NA, pC = NA))
  }
  
  get_int <- function(code) {
    freq_intervals[freq_intervals$code == code, c("min_m", "max_m")]
  }
  
  sea_i    <- get_int(sea)
  river_i  <- get_int(river)
  frozen_i <- get_int(frozen)
  canned_i <- get_int(canned)
  
  sea_vals    <- runif(n_sim, sea_i$min_m,    sea_i$max_m)
  river_vals  <- runif(n_sim, river_i$min_m,  river_i$max_m)
  frozen_vals <- runif(n_sim, frozen_i$min_m, frozen_i$max_m)
  canned_vals <- runif(n_sim, canned_i$min_m, canned_i$max_m)
  
  total <- sea_vals + river_vals + frozen_vals + canned_vals
  
  pA <- mean(total < 1)
  pB <- mean(total >= 1 & total <= 3)
  pC <- mean(total > 3)
  
  probs <- c(A = pA, B = pB, C = pC)
  cat_ml <- names(probs)[which.max(probs)]
  
  list(cat = cat_ml, pA = pA, pB = pB, pC = pC)
}

## ==========================
## 6. Run Monte-Carlo
## ==========================
set.seed(123)

dat_out <- dat %>%
  mutate(
    res = pmap(
      list(sea_fish, river_fish, frozen_fish, canned_fish),
      ~ simulate_category(..1, ..2, ..3, ..4, n_sim = 5000)
    ),
    fish_new = sapply(res, `[[`, "cat"),
    pA = sapply(res, `[[`, "pA"),
    pB = sapply(res, `[[`, "pB"),
    pC = sapply(res, `[[`, "pC")
  ) %>%
  select(-res)

## ==========================
## 7. Save results
## ==========================
saveRDS(
  dat_out,
  file.path(DERIVED_DIR, "hbmii_fish_harmonised.rds")
)

write.xlsx(
  dat_out,
  file.path(DERIVED_DIR, "hbmii_fish_harmonised.xlsx"),
  overwrite = TRUE
)

cat("HBM-II fish harmonisation completed.\n")

