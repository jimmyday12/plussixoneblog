# First get data
# Script to run weekly updating of data, ratings simulations and predictions. Data should be saved into github for us by blog.

# preamble ----------------------------------------------------------------
# Load libraries
library(pacman)
pacman::p_load(fitzRoy, tidyverse, elo, here, lubridate, tibbletime)

# Get Data ----------------------------------------------------------------
# Get fixture data using FitzRoy
fixture <- fitzRoy::get_fixture() %>%
  filter(Date > Sys.Date()) %>%
  mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
  rename(Round.Number = Round)

# Get results
results <- fitzRoy::get_match_results() %>%
  mutate(
    seas_rnd = paste0(Season, ".", Round.Number),
    First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
  )

# Bind together
game_dat <- bind_rows(results, fixture) %>%
  mutate(Game = row_number())

# Get states data - this comes from another script I run when a new venue or team occurs
states <- read_rds(here("data", "raw-data", "states.rds"))

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

# Create function

# Optimiser - takes a while
eloOptim <- function(par, dat){
  # Extract parameters
  #B <- par[1]
  #k_val <- par[2]
  #carryOver <- par[3]
  B <- par[6]
  k_val <- par[4]
  carryOver <- par[5]
  e <- par[1]
  d <- par[2]
  h <- par[3]
  results <- dat
  
  map_margin_to_outcome <- function(margin, B = 0.025) {
    1 / (1 + (exp(-B * margin)))
  }
  
  # Inverse of above, convert outcome to margin
  map_outcome_to_margin <- function(outcome, B = 0.025) {
    log((1 / outcome) - 1) / - B
  }
  
  # Function to calculate k (how much weight we add to each result)
  calculate_k <- function(margin, k_val) {
    k_val * log(abs(margin) + 1)
  }
  
  # Not using: function to calculate HGA adjust
  calculate_hga <- function(experience, interstate, home.team, e = 1, d = 1, h = 1){
    (e * log(experience)) +  (d * as.numeric(interstate)) + (h * home.team)
  }
  
  elo.data <- elo.run(
    map_margin_to_outcome(Home.Points - Away.Points, B = B) ~
      adjust(Home.Team, 
             calculate_hga(Home.Venue.Exp, Home.Interstate, Home.Factor, e = e, d = d, h = h)) +
      adjust(Away.Team, 
             calculate_hga(Away.Venue.Exp, Away.Interstate, Away.Factor, e = e, d = d, h = h)) +
      group(seas_rnd) +
      regress(First.Game, 1500, carryOver) +
      k(calculate_k(Home.Points - Away.Points, k_val)),
    data = results
  )
  
  results_processed <- results %>%
    bind_cols(as.data.frame(elo.data)) %>%
    rename(
      ELO.Home = elo.A,
      ELO.Away = elo.B,
      pred.Prob = p.A
    ) %>%
    mutate(pred.Margin = map_outcome_to_margin(pred.Prob)) %>%
    select(-team.A, -team.B, -wins.A, -update)
  err <- mean(abs(results_processed$Margin - results_processed$pred.Margin))
  return(err)
}

# Run Optim calculation -----------------------------------------------------
# Get results
results <- game_dat %>%
  filter(Date < Sys.Date())

# Loop through these
# Set Parameters
B <- 0.025
k_val <- 18.8
carryOver <- 0.07
e = 2.2
d = -23.7
h = 29.2

pars <- c(e, d, h, k_val, carryOver, B)


# Do optimisation
opt_results <- optim(pars,
                     method = "L-BFGS-B",
                     lower = c(-Inf, -Inf, -Inf, -Inf, 0, -Inf),
                     upper = c(Inf, Inf, Inf, Inf, 1, Inf),
                     fn = eloOptim,
                     dat = results,
                     control = list(maxit = 1000))
