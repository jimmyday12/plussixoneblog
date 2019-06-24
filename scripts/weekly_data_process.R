# Script to run weekly updating of data, ratings simulations and predictions. Data should be saved into github for us by blog.
ptm <- proc.time()


# preamble ----------------------------------------------------------------
# Load libraries
library(fitzRoy)
library(pacman)
pacman::p_load(tidyverse, elo, here, lubridate, tibbletime)


filt_date <- Sys.Date()

fixture <- fitzRoy::get_fixture() %>%
  filter(Date >= filt_date)

fixture_bug <- FALSE
grand_final_bug <- FALSE
season <- 2019


# Set Parameters
e <- 1.7
d <- -32
h <- 20
k_val <- 20
carryOver <- 0.05
B <- 0.04
sim_num <- 10000

# Get Data ----------------------------------------------------------------

# Get fixture data using FitzRoy
fixture <- fixture %>%
  mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
  rename(Round.Number = Round)

if (grand_final_bug){
# temp
fixture <- tibble(
  Date = ymd("2018/09/29"),
  Season = 2018,
  Season.Game = 1,
  Round = "28",
  Round.Number = 28,
  Home.Team = "West Coast",
  Away.Team = "Collingwood",
  Venue = "MCG"
)
}

if(fixture_bug) fixture$Round.Number = fixture$Round.Number - 1

# Get results
results <- fitzRoy::get_match_results() %>%
  mutate(
    seas_rnd = paste0(Season, ".", Round.Number),
    First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
  )


# Get states data - this comes from another script I run when a new venue or team occurs
states <- read_rds(here::here("data", "raw-data", "states.rds"))
message("Data loaded")

# Data Cleaning -----------------------------------------------------------
# Fix Venues
venue_fix <- function(x){
  case_when(
    x == "MCG" ~ "M.C.G.",
    x == "SCG" ~ "S.C.G.",
    x == "Etihad Stadium" ~ "Docklands",
    x == "Marvel Stadium" ~ "Docklands",
    x == "Blundstone Arena" ~ "Bellerive Oval",
    x == "GMHBA Stadium" ~ "Kardinia Park",
    x == "Spotless Stadium" ~ "Blacktown",
    x == "Showground Stadium" ~ "Blacktown",
    x == "UTAS Stadium" ~ "York Park",
    x == "Mars Stadium" ~ "Eureka Stadium",
    x == "Adelaide Arena at Jiangwan Stadium" ~ "Jiangwan Stadium",
    x == "TIO Traegar Park" ~ "Traeger Park",
    x == "Metricon Stadium" ~ "Carrara",
    x == "TIO Stadium" ~ "Marrara Oval",
    x == "Optus Stadium" ~ "Perth Stadium",
    x == "Canberra Oval" ~ "Manuka Oval",
    x == "UNSW Canberra Oval" ~ "Manuka Oval",
    TRUE ~ as.character(x)
  )
}

# Bind together and fix stadiums
game_dat <- bind_rows(results, fixture) %>%
  mutate(Game = row_number()) %>%
  ungroup() %>%
  mutate(Venue = venue_fix(Venue)) %>%
  mutate(Round = Round.Number)

# ELO Preparation --------------------------------------------------------
# First some helper functions. These are used to adjust margin/outcome/k/HGA
# Squash margin between 0 and 1
map_margin_to_outcome <- function(margin, B) {
  1 / (1 + (exp(-B * margin)))
}

# Inverse of above, convert outcome to margin
map_outcome_to_margin <- function(outcome, B) {
  #log((1 / outcome) - 1) / - B
  (-log((1 - outcome)/outcome))/B
}

# Function to calculate k (how much weight we add to each result)
calculate_k <- function(margin, k_val, round) {
  mult <- (log(abs(margin) + 1) - log(round))
  x <- k_val * ifelse(mult <= 0, 1, mult)
  ifelse(x < k_val, k_val, x)
}

# Not using: function to calculate HGA adjust
calculate_hga <- function(experience, interstate, home.team, e, d, h){
  (e * log(experience)) +  (d * as.numeric(interstate)) + (h * home.team)
}

# Prep calculations
# We want to calculate the experience and interstate value for each team

# Experience - number of games in last 100
# Create rolling function
last_n_games = 100
count_games <- rollify(function(x) sum(last(x) == x), window = last_n_games, na_value = NA)

# Make data long and apply our function
game_dat_long <- game_dat %>%
  gather(Status, Team, Home.Team, Away.Team)  %>% 
  group_by(Team) %>%
  arrange(Team, Game) %>%
  mutate(venue_experience = count_games(Venue)) %>%
  group_by(Team, Venue) %>%
  mutate(venue_experience = ifelse(is.na(venue_experience), row_number(Team), venue_experience)) %>%
  ungroup() %>%
  select(Game, Team, venue_experience)

# Add back into wide dataset
game_dat <- game_dat %>%
  left_join(game_dat_long, by = c("Game", "Home.Team" = "Team")) %>%
  rename(Home.Venue.Exp = venue_experience) %>%
  left_join(game_dat_long, by = c("Game", "Away.Team" = "Team")) %>%
  rename(Away.Venue.Exp = venue_experience)

## Add interstate
get_state <- function(team, venue, all_teams = states$team, all_venues = states$venue){
  all_teams$State[match(team, all_teams$Team)] != all_venues$State[match(venue, all_venues$Venue)]
}

game_dat <- game_dat %>%
  mutate(Home.Interstate = get_state(Home.Team, Venue),
         Away.Interstate = get_state(Away.Team, Venue),
         Home.Factor = 1,
         Away.Factor = 0)
  
# Run ELO calculation -----------------------------------------------------
# Get results
results <- game_dat %>%
  filter(Date < filt_date)

# Run ELO
elo.data <- elo.run(
  map_margin_to_outcome(Home.Points - Away.Points, B = B) ~
  adjust(Home.Team, 
         calculate_hga(Home.Venue.Exp, Home.Interstate, Home.Factor, e = e, d = d, h = h)) +
    adjust(Away.Team, 
           calculate_hga(Away.Venue.Exp, Away.Interstate, Away.Factor, e = e, d = d, h = h)) +
    group(seas_rnd) +
    regress(First.Game, 1500, carryOver) +
    k(calculate_k(Home.Points - Away.Points, k_val, Round.Number)),
  data = results
)

# Need to combine this with results to get into long format. May be able to simplify.
elo <- results %>%
  bind_cols(as.data.frame(elo.data)) %>%
  rename(
    Home.ELO = elo.A,
    Away.ELO = elo.B
  ) %>%
  mutate(
    Home.ELO_pre = Home.ELO - update,
    Away.ELO_pre = Away.ELO + update
  ) %>%
  select(Date, Game, Round, Round.Number, Home.Team, Away.Team, Home.ELO:Away.ELO_pre) %>%
  gather(variable, value, Home.Team:Away.ELO_pre) %>%
  separate(variable, into = c("Status", "variable"), sep = "\\.") %>%
  spread(variable, value) %>%
  mutate(ELO = as.numeric(ELO), ELO_pre = as.numeric(ELO_pre)) %>%
  group_by(Team) %>%
  arrange(Game) 

# Also add predicted margin and probability to results
results <- results %>%
  mutate(Probability = round(predict(elo.data, newdata = results), 3),
         Prediction = ceiling(map_outcome_to_margin(Probability, B = B)))


# Message
print(proc.time() - ptm)
message("ELO Run")

# Predictions -------------------------------------------------------------
# Do predictions
fixture <- game_dat %>%
  filter(Date >= filt_date)


predictions_raw <- fixture %>%
  mutate(
    Day = format(Date, "%a, %d"),
    Time = format(Date, "%H:%M"),
    Probability = round(predict(elo.data, newdata = fixture), 3),
    Prediction = round(map_outcome_to_margin(Probability, B = B), 1),
    Result = case_when(
      Probability > 0.5 ~ paste(Home.Team, "by", round(Prediction, 0)),
      Probability < 0.5 ~ paste(Away.Team, "by", -round(Prediction, 0)),
      TRUE ~ "Draw"
    )
  ) 


predictions <- predictions_raw %>% 
  select(Day, Time, Round.Number, Venue, Home.Team, 
         Away.Team, Prediction, Probability, Result)
predictions
# Simulation --------------------------------------------------------------
sim_res <- results %>%
  filter(year(Date) == year(Sys.Date())) %>%
  mutate(
    Season.Game = Game - min(Game) + 1,
    Round = Round.Number
  )

remaining_fixture <- 
  game_dat %>%
  filter(Date >= filt_date)

# Get ELOS and perturb them
form <- elo:::clean_elo_formula(stats::terms(elo.data)) # needed for elo.prob
perturb_elos <- function(x) {
  x <- final.elos(x) + rnorm(length(x$teams), mean = 0, sd = 65)
  x + 1500 - mean(x)
  } # function to map over

# Do simulations
#sims <- 1:5
sims <- 1:sim_num

res <- sims %>%
  map_df(~mutate(sim_res, Sim = .x))

message("Simulating")

# Now simulate
sim_data <- sims %>%
  rep_along(list(elo.data)) %>%
  map(perturb_elos) %>%
  map(~elo.prob(form, data = remaining_fixture, elos = .x)) %>%
  map2_df(sims, ~mutate(
    remaining_fixture, Probability = .x,
    Margin = ceiling(map_outcome_to_margin(Probability, B = B)),
    Sim = .y)) %>%
  bind_rows(res)


# Summarise simulated data
win_calc <- function(x) case_when(x == 0 ~ 0.5, x > 0 ~ 1, TRUE ~ 0)

sim_data_all <- sim_data %>%
  gather(Status, Team, Home.Team:Away.Team) %>%
  filter(str_detect(Status, "Team")) %>%
  mutate(
    Margin = ifelse(Status == "Home.Team", Margin, -Margin),
    Win = win_calc(Margin)
  ) %>%
  group_by(Sim, Team) %>%
  summarise(
    Wins = sum(Win),
    Margin = sum(Margin)
  ) %>%
  group_by(Sim) %>%
  arrange(desc(Margin)) %>%
  mutate(
    Rank = row_number(desc(Wins)),
    Top.8 = Rank < 9,
    Top.4 = Rank < 5,
    Top.1 = Rank == 1
  )


# Summarise the simulations into percentages
sim_data_summary <- sim_data_all %>%
  group_by(Team) %>%
  dplyr::summarise(
    Season = last(results$Season),
    Round = last(results$Round.Number),
    Margin = mean(Margin),
    Wins = mean(Wins),
    Top.8 = sum(Top.8) / max(sims),
    Top.4 = sum(Top.4) / max(sims),
    Top.1 = sum(Top.1) / max(sims)
  )

# Combine these simulations with previous ones for plotting
# Load old sims
past_sims <- read_rds(here::here("data", "raw-data", "AFLM_sims.rds")) 

# Bind with last entry
sim_data_summary <- past_sims$sim_data_summary %>%
  filter(!(Round == last(results$Round.Number)  & 
             Season == last(results$Season))) %>%
  bind_rows(sim_data_summary)

# Print to console
sim_data_summary %>% 
  filter(Round == last(results$Round.Number))

# MEssage
print(proc.time() - ptm)
("Sims done")

# Count finishing position probability ------------------------------------
# Get Table of percentages
simCount <-
  sim_data_all %>%
  ungroup() %>%
  select(Team, Rank) %>%
  table() %>%
  as.data.frame() %>%
  group_by(Team) %>%
  mutate(Freq = Freq/sim_num * 100) 

simCount$Freq[simCount$Freq == 0] <- NA

## Reorder table by number of wins
# Find order of wins
simWins <- 
  sim_data_summary %>%
  filter(Round == max(Round)) %>%
  arrange(Wins)

# Refactor
simCount$Team <- factor(simCount$Team, levels = simWins$Team)

# Get rankings within team
simCount <- simCount %>% 
  group_by(Team) %>% 
  mutate(order = dense_rank(desc(Freq)),
         txt = case_when(
           Freq < 1 ~ "<1", 
           Freq > 1 ~ as.character(round(Freq, 0)), 
           TRUE ~ "")) %>%
  arrange(Team, order) 

# Add current margin/year
simCount <- simCount %>%
  mutate(Season = last(sim_data_summary$Season),
         Round = last(sim_data_summary$Round))

# Combine with saved
if ("simCount" %in% names(past_sims)) {
simCount <- past_sims$simCount %>%
  #filter(Season == season) %>%
  filter(!(Round == last(results$Round.Number)  & 
           Season == last(results$Season))) %>%
  bind_rows(simCount)
}

# Save Data ---------------------------------------------------------------
# Create list
aflm_data <- list(
  results = results,
  elo.data = elo.data, 
  elo = elo, 
  predictions = predictions)

aflm_sims <- list(
  sim_data_summary = sim_data_summary,
  sim_data_all = sim_data_all,
  simCount = simCount
)

# Save
write_rds(aflm_data, path = here::here("data", "raw-data", "AFLM.rds"), compress = "bz")
write_rds(aflm_sims, path = here::here("data", "raw-data", "AFLM_sims.rds"), compress = "bz")
write_csv(predictions, path = here::here("data", "raw-data", "predictions.csv"))
write_csv(aflm_sims$sim_data_summary, path = here::here("data", "raw-data", "AFLM_sims_summary.csv"))
write_csv(aflm_sims$simCount, path = here::here("data", "raw-data", "AFLM_sims_positions.csv"))

# Message
print(proc.time() - ptm)
message("Data saved")

blogdown:::serve_site()