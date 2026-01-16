
# R/config.R
# ============================================================
# Project configuration
# Edit PROJECT_DIR to match your local setup
# ============================================================

PROJECT_DIR <- "PATH/TO/YOUR/PROJECT"     # You edit this line to match your local setup

INPUT_DIR   <- file.path(PROJECT_DIR, "data")
DERIVED_DIR <- file.path(PROJECT_DIR, "derived")
OUTPUT_DIR  <- file.path(PROJECT_DIR, "outputs")

# Create folders if they don't exist
dir.create(INPUT_DIR,   showWarnings = FALSE, recursive = TRUE)
dir.create(DERIVED_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(OUTPUT_DIR,  showWarnings = FALSE, recursive = TRUE)

