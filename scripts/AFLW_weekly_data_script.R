# Womens script

# Setup
library(fitzRoy)
library(tidyverse)

seas <- 2021

# Get data ---------------------------------------------------------------------
results <- fetch_results_afl(2012:seas, comp = "AFLW")

fixture <- fetch_fixture_afl(seas, comp = "AFLW")
fixture <- fixture %>%
  filter(status != "CONCLUDED")

ladder <- fetch_ladder_afl(seas, comp = "AFLW")

# Do ELOS ----------------------------------------------------------------------

# Simulate Season --------------------------------------------------------------

# Simulate Finals --------------------------------------------------------------

# Save data