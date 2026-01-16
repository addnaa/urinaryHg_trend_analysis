# =============================================================================
# Combo plot: Urinary Hg trends + amalgams + fish consumption
# Uses harmonised dataset from Script 03
# =============================================================================

library(dplyr)
library(ggplot2)
library(scales)

options(scipen = 999)

# -----------------------------------------------------------------------------
# 1. Load harmonised analysis dataset
# -----------------------------------------------------------------------------

data <- readRDS("derived/analysis_dat_complete_cases.rds")

# -----------------------------------------------------------------------------
# 2. UHg summary by calendar year
# -----------------------------------------------------------------------------

summary_uhg <- data %>%
  filter(!is.na(uhg_ngml), !is.na(year)) %>%
  mutate(year = as.numeric(year)) %>%
  group_by(year) %>%
  summarise(
    n          = n(),
    Q1_uHg     = quantile(uhg_ngml, 0.25, na.rm = TRUE),
    median_uHg = median(uhg_ngml, na.rm = TRUE),
    Q3_uHg     = quantile(uhg_ngml, 0.75, na.rm = TRUE),
    .groups    = "drop"
  )

# quadratic trend for medians
fit_quad <- lm(median_uHg ~ poly(year, 2, raw = TRUE), data = summary_uhg)

year_grid <- data.frame(
  year = seq(min(summary_uhg$year), max(summary_uhg$year), length.out = 200)
)
year_grid$uHg_fit <- predict(fit_quad, year_grid)

# -----------------------------------------------------------------------------
# 3. Percentages: amalgams and fish
# -----------------------------------------------------------------------------

# Amalgams (% yes)
amalgam_long <- data %>%
  filter(!is.na(amalgam_yes_no), !is.na(year)) %>%
  mutate(
    year = as.numeric(year),
    has_amalgam = amalgam_yes_no == 1
  ) %>%
  group_by(year) %>%
  summarise(
    value = 100 * mean(has_amalgam),
    group = "Amalgam: yes",
    .groups = "drop"
  )

# Fish categories (% per year)
fish_long <- data %>%
  filter(!is.na(fish_new), !is.na(year)) %>%
  mutate(
    year = as.numeric(year),
    fish_new = factor(
      fish_new,
      levels = c("A", "B", "C"),
      labels = c("Fish: low", "Fish: medium", "Fish: high")
    )
  ) %>%
  group_by(year) %>%
  mutate(n_year = n()) %>%
  ungroup() %>%
  group_by(year, fish_new) %>%
  summarise(
    value = 100 * n() / first(n_year),
    .groups = "drop"
  ) %>%
  rename(group = fish_new)

plot_df <- bind_rows(amalgam_long, fish_long)

# -----------------------------------------------------------------------------
# 4. Scaling percentages to Hg axis
# -----------------------------------------------------------------------------

uHg_max <- 2  # ng/mL, chosen for interpretability

plot_df <- plot_df %>%
  mutate(
    group = factor(
      group,
      levels = c("Amalgam: yes", "Fish: low", "Fish: medium", "Fish: high")
    ),
    value_scaled = value / 100 * uHg_max
  )

# -----------------------------------------------------------------------------
# 5. Plot
# -----------------------------------------------------------------------------

fish_offset    <- -0.2
amalgam_offset <-  0.2

all_years <- sort(unique(summary_uhg$year))

p_combined <- ggplot() +
  
  # Fish bars (stacked)
  geom_col(
    data = subset(plot_df, group != "Amalgam: yes"),
    aes(x = year + fish_offset, y = value_scaled, fill = group),
    width = 0.4,
    position = position_stack(vjust = 0)
  ) +
  
  # Amalgam bar
  geom_col(
    data = subset(plot_df, group == "Amalgam: yes"),
    aes(x = year + amalgam_offset, y = value_scaled, fill = group),
    width = 0.4
  ) +
  
  # UHg IQR
  geom_errorbar(
    data = summary_uhg,
    aes(x = year, ymin = Q1_uHg, ymax = Q3_uHg),
    colour = "red3",
    linewidth = 1.2
  ) +
  
  # UHg median
  geom_point(
    data = summary_uhg,
    aes(x = year, y = median_uHg),
    colour = "darkred",
    size = 4
  ) +
  
  # Trend
  geom_line(
    data = year_grid,
    aes(x = year, y = uHg_fit),
    colour = "red3",
    linewidth = 1
  ) +
  
  scale_x_continuous(
    breaks = all_years,
    limits = c(min(all_years) - 0.8, max(all_years) + 0.8)
  ) +
  
  scale_y_continuous(
    name = "Urinary Hg (ng mL\u207B\u00B9)",
    limits = c(0, uHg_max + 0.1),
    breaks = seq(0, uHg_max, by = 0.5),
    sec.axis = sec_axis(
      ~ . / uHg_max * 100,
      breaks = seq(0, 100, by = 25),
      name = "Percentage of children (%)"
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
  
  labs(x = "Year") +
  
  theme_bw(base_size = 14) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.x        = element_text(angle = 45, hjust = 1),
    legend.position    = "top"
  )

ggsave(
  "outputs/figures/uHg_trend_percentages.svg",
  p_combined,
  width = 7.2,
  height = 3.8
)
