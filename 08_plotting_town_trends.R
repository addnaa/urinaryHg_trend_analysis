############################################################
# 07_plots_towns_uhg.R
#
# PURPOSE
#   Produce town-specific trend plots (Idrija, Ljubljana)
#   for urinary mercury:
#     - raw (ng/mL)
#     - creatinine-adjusted (µg/g creatinine)
#
#   Each plot combines:
#     - Median + IQR of urinary Hg (left axis)
#     - % children with amalgams
#     - % fish consumption categories (A/B/C)
#
#   Percentages are mapped to the Hg axis and shown
#   on a secondary y-axis.
#
# INPUT
#   derived/analysis_dat_complete_cases.rds   (from Script 03)
#
# OUTPUT
#   figures/uHg_ngml_trend_percentages_<town>.svg
#   figures/uHg_creat_trend_percentages_<town>.svg
############################################################

rm(list = ls())

# ============================================================
# 0. Libraries & paths
# ============================================================
library(dplyr)
library(ggplot2)
library(scales)

source("R/config.R")

FIG_DIR <- file.path(OUTPUT_DIR, "figures")
dir.create(FIG_DIR, showWarnings = FALSE, recursive = TRUE)

options(scipen = 999)

# ============================================================
# 1. Load analysis dataset (from Script 03)
# ============================================================
dat <- readRDS(file.path(DERIVED_DIR, "analysis_dat_complete_cases.rds"))

towns <- c("Idrija", "Ljubljana")

# ============================================================
# 2. Helper function to create town plots
# ============================================================

make_town_plot <- function(
    data,
    town_name,
    outcome_var,
    ylab,
    outfile,
    headroom = 0.3
) {
  
  data_town <- data %>%
    filter(town_id == town_name)
  
  # ---- Hg summary by year ----
  summ_hg <- data_town %>%
    filter(!is.na(.data[[outcome_var]]), !is.na(year)) %>%
    mutate(year = as.numeric(year)) %>%
    group_by(year) %>%
    summarise(
      Q1     = quantile(.data[[outcome_var]], 0.25, na.rm = TRUE),
      median = median(.data[[outcome_var]], na.rm = TRUE),
      Q3     = quantile(.data[[outcome_var]], 0.75, na.rm = TRUE),
      .groups = "drop"
    )
  
  if (nrow(summ_hg) == 0) return(NULL)
  
  # ---- define town-specific Hg scale ----
  y_max <- max(summ_hg$Q3, na.rm = TRUE) + headroom
  
  # ---- pseudo-time axis (centered) ----
  years <- sort(unique(summ_hg$year))
  year_map <- data.frame(
    year = years,
    x    = seq_along(years)
  )
  
  summ_hg <- summ_hg %>% left_join(year_map, by = "year")
  
  # ---- percentages: amalgams ----
  amalgam <- data_town %>%
    filter(!is.na(amalgam_yes_no), !is.na(year)) %>%
    group_by(year) %>%
    summarise(
      value = 100 * mean(amalgam_yes_no == 1),
      group = "Amalgam: yes",
      .groups = "drop"
    )
  
  # ---- percentages: fish ----
  fish <- data_town %>%
    filter(!is.na(fish_new), !is.na(year)) %>%
    mutate(
      fish_new = factor(
        fish_new,
        levels = c("A","B","C"),
        labels = c("Fish: low","Fish: medium","Fish: high")
      )
    ) %>%
    group_by(year, fish_new) %>%
    summarise(
      value = 100 * n() / sum(n()),
      .groups = "drop"
    ) %>%
    rename(group = fish_new)
  
  plot_df <- bind_rows(amalgam, fish) %>%
    left_join(year_map, by = "year") %>%
    mutate(
      group = factor(
        group,
        levels = c("Amalgam: yes", "Fish: low", "Fish: medium", "Fish: high")
      ),
      value_scaled = value / 100 * y_max
    )
  
  # ---- plotting ----
  p <- ggplot() +
    
    # Fish bars (stacked)
    geom_col(
      data = filter(plot_df, group != "Amalgam: yes"),
      aes(x = x - 0.15, y = value_scaled, fill = group),
      width = 0.3
    ) +
    
    # Amalgam bar (separate)
    geom_col(
      data = filter(plot_df, group == "Amalgam: yes"),
      aes(x = x + 0.15, y = value_scaled, fill = group),
      width = 0.3
    ) +
    
    # IQR
    geom_errorbar(
      data = summ_hg,
      aes(x = x, ymin = Q1, ymax = Q3),
      colour = "red3",
      linewidth = 1
    ) +
    
    # Median
    geom_point(
      data = summ_hg,
      aes(x = x, y = median),
      colour = "darkred",
      size = 4
    ) +
    
    # Line
    geom_line(
      data = summ_hg,
      aes(x = x, y = median),
      colour = "red3",
      linewidth = 0.8
    ) +
    
    scale_x_continuous(
      breaks = year_map$x,
      labels = year_map$year,
      expand = c(0, 0)
    ) +
    
    scale_y_continuous(
      name = ylab,
      limits = c(0, y_max),
      sec.axis = sec_axis(
        ~ . / y_max * 100,
        name = "Percentage of children (%)",
        breaks = seq(0, 100, by = 25)
      )
    ) +
    
    scale_fill_manual(
      values = c(
        "Amalgam: yes" = "darkolivegreen4",
        "Fish: low"    = "bisque1",
        "Fish: medium" = "bisque3",
        "Fish: high"   = "burlywood4"
      ),
      name = NULL
    ) +
    
    labs(
      x = "Sampling year",
      title = town_name
    ) +
    
    theme_bw(base_size = 14, base_family = "Arial") +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      axis.text.x        = element_text(angle = 45, hjust = 1),
      panel.border       = element_rect(colour = "grey50", fill = NA),
      legend.position    = "top"
    )
  
  ggsave(outfile, p, width = 5, height = 3.8, units = "in")
}

# ============================================================
# 3. Produce plots
# ============================================================

for (tn in towns) {
  
  make_town_plot(
    data        = dat,
    town_name   = tn,
    outcome_var = "uhg_ngml",
    ylab        = "Urinary Hg (ng mL⁻¹)",
    outfile     = file.path(FIG_DIR, paste0("uHg_ngml_trend_percentages_", tn, ".svg"))
  )
  
  make_town_plot(
    data        = dat,
    town_name   = tn,
    outcome_var = "uhg_creat",
    ylab        = "Urinary Hg (µg g⁻¹ creatinine)",
    outfile     = file.path(FIG_DIR, paste0("uHg_creat_trend_percentages_", tn, ".svg"))
  )
}

message("Town plots completed: Idrija & Ljubljana.")
