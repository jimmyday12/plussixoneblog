# Testing geom_smooth
library(tidyverse)
library(here)

# Load data
#dat_list <- read_rds(here("data", "raw-data", "AFLM.rds"))
#results <- dat_list$results

res_small <- results %>%
  mutate(win = case_when(
    Margin > 0 ~ 1,
    TRUE ~ 0
  )) %>%
  filter(Season > 1999)

  ggplot(aes(x = Prediction, y = win)) +
stat_smooth(method="glm", method.args = list(family = "binomial"),
            formula = y ~ x)
