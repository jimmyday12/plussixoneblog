# Load packages
#devtools::install_github("jimmyday12/monash_tipr")
library(monashtipr)
library(fitzRoy)
library(tidyverse)

# Get user/password
user <- Sys.getenv("MONASH_REAL_USER")
pass =  Sys.getenv("MONASH_REAL_PASS")

# Function to map my predictions names to monash names
map_names_to_monash <- function(names) {
  dplyr::case_when(
    names == "Footscray" ~ "W_Bulldogs",
    names == "North Melbourne" ~ "Kangaroos",
    names == "St Kilda" ~ "St_Kilda",
    names == "West Coast" ~ "W_Coast",
    names == "Gold Coast" ~ "Gold_Coast",
    names == "Port Adelaide" ~ "P_Adelaide",
    names == "Brisbane Lions" ~ "Brisbane",
    names == "GWS" ~ "G_W_Sydney", 
    TRUE ~ names
  )
}

# Read in predictions and update names and fields
predictions <- read_csv(here::here("data_files", "raw-data", "predictions.csv")) %>%
  filter(Round.Number == min(Round.Number)) %>%
  mutate_at(c("Home.Team", "Away.Team"), map_names_to_monash) %>%
  mutate(Margin = round(Prediction),
         `Std. Dev.` = 40) %>%
  rename(Home = Home.Team, 
         Away = Away.Team) %>%
  select(Home, Away, Margin, `Std. Dev.`, Probability)


# Join to tips
monash_games <- get_games(user, pass, comp = "normal")

pred_games <- monash_games %>%
  select(-Margin) %>%
  left_join(predictions, by = c("Home", "Away"))

pred_games

# Submit - normal
pred_games %>%
  select(-`Std. Dev.`, -Probability) %>%
  monashtipr::submit_tips(user = user, pass = pass, comp = "normal")

# Submit - gauss
pred_games %>%
  select(-Probability) %>%
  monashtipr::submit_tips(user = user, pass = pass, comp = "gauss")

# Submit - prob
pred_games %>%
  select(-`Std. Dev.`, -Margin) %>%
  monashtipr::submit_tips(user = user, pass = pass, comp = "info")
