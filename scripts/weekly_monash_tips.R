# Load packages
#devtools::install_github("jimmyday12/monash_tipr", force = TRUE)
library(monashtipr)
#devtools::load_all("/Users/jamesday/R/monashtipr")
library(fitzRoy)
library(tidyverse)

# Get user/password
user <- Sys.getenv("MONASH_REAL_USER")
pass =  Sys.getenv("MONASH_REAL_PASS")
user
pass
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
predictions <- read_csv(here::here("data_files", "raw-data", "predictions.csv")) 

round <- min(predictions$Round.Number)

round_fnc <- function(x) {
  if(abs(x) > 1) {
    return(round(x)) 
  } else if(x < 0) {
      return(floor(x))
  } else {
      return(ceiling(x))
    }
}
  
#round <- 15
#round <- 16
  
predictions <- predictions %>%
  filter(Round.Number == min(Round.Number)) %>%
  mutate_at(c("Home.Team", "Away.Team"), map_names_to_monash) %>%
  group_by(Home.Team, Away.Team) %>%
  mutate(Margin = round_fnc(Prediction),
         `Std. Dev.` = 40) %>%
  rename(Home = Home.Team, 
         Away = Away.Team) %>%
  select(Home, Away, Margin, `Std. Dev.`, Probability)


# Join to tips
monash_games <- get_games(user, pass, comp = "normal", round = round)

pred_games <- monash_games %>%
  select(-Margin) %>%
  left_join(predictions, by = c("Home" = "Home", "Away" = "Away"))

## Custom fix for Saints v Sydney R10 2021
#pred_games$Margin[1] <- -predictions$Margin[5]
#pred_games$`Std. Dev.`[1] <- predictions$`Std. Dev.`[5]
#pred_games$Probability[1] <- 1-predictions$Probability[5]

#pred_games$Margin[6] <- -predictions$Margin[5]
#pred_games$`Std. Dev.`[6] <- predictions$`Std. Dev.`[5]
#pred_games$Probability[6] <- 1-predictions$Probability[5]

pred_games

# Submit - normal
x <- pred_games %>%
  select(-`Std. Dev.`, -Probability) %>%
  monashtipr::submit_tips(user = user, pass = pass, round = round, comp = "normal")

x

#pred_games %>%
#  select(-`Std. Dev.`, -Probability) %>%
#  write_csv("/Users/jamesday/R/monashtipr/test.csv")

# Submit - gauss
pred_games %>%
  select(-Probability) %>%
  monashtipr::submit_tips(user = user, pass = pass, round = round, comp = "gauss")

# Submit - prob
pred_games %>%
  select(-`Std. Dev.`, -Margin) %>%
  monashtipr::submit_tips(user = user, pass = pass, round = round, comp = "info")

# Write results
x <- x %>%
  mutate(Date = Sys.time(),
         Round = round)

write_csv(x, here::here("monash_latest.csv"))
