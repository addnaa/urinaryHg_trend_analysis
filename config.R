
# R/config.R
# ============================================================
# Project configuration
# IMPORTANT:
#   Replace PROJECT_DIR with the local path where this
#   repository is stored on your computer.
#
# Example:
#   PROJECT_DIR <- "C:/Users/yourname/Documents/Hg_Project"
# ============================================================

PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"     # You edit this line to match your local setup

INPUT_DIR   <- file.path(PROJECT_DIR, "data")
DERIVED_DIR <- file.path(PROJECT_DIR, "derived")
OUTPUT_DIR  <- file.path(PROJECT_DIR, "outputs")

# Create folders if they don't exist
dir.create(INPUT_DIR,   showWarnings = FALSE, recursive = TRUE)
dir.create(DERIVED_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_DIR,  showWarnings = FALSE, recursive = TRUE)


