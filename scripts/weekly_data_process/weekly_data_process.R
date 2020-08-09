# Script to run weekly updating of data, ratings simulations and predictions. Data should be saved into github for us by blog.
ptm <- proc.time()
message("Starting Script")
# Preamble ----------------------------------------------------------------
# Load libraries
library(fitzRoy)
library(pacman)
pacman::p_load(tidyverse, elo, here, lubridate, tibbletime)

# source functions
source(here::here("scripts", "weekly_data_process", "0-functions.R"))
source(here::here("scripts", "weekly_data_process", "1-get-data.R"))
source(here::here("scripts", "weekly_data_process", "2-elo_prep.R"))
source(here::here("scripts", "weekly_data_process", "2a-covid_fix.R"))
source(here::here("scripts", "weekly_data_process", "3-elo-run.R"))
source(here::here("scripts", "weekly_data_process", "4-sims.R"))
source(here::here("scripts", "weekly_data_process", "5-finals_sims.R"))

# Set some parameters
filt_date <- Sys.Date()
fixture_bug <- FALSE
grand_final_bug <- FALSE
season <- 2020
new_season <- FALSE

# Set ELO Parameters
e <- 1.7
d <- -32
h <- 20
k_val <- 20
carryOver <- 0.05
B <- 0.04
sim_num <- 10000

# Get Data ----------------------------------------------------------------
# First check if new games exist
new_results <- get_footywire_match_results(2020, 1) %>% convert_results()
old_results <- read_rds(here::here("data_files", "raw-data", "AFLM.rds"))
if (last(old_results$results$Home.Team) == last(new_results$Home.Team) &
  last(old_results$results$Away.Team) == last(new_results$Away.Team) &
  last(old_results$results$Date) == last(new_results$Date)) {
  new_data <- FALSE
  message("No New Data Found")
} else {
  new_data <- TRUE
  message("New Data Found")
}

# Manual override
new_data <- TRUE
if (new_data) {
  dat <- get_data(season,
    filt_date,
    grand_final_bug = grand_final_bug,
    fixture_bug = fixture_bug
  )


  print(proc.time() - ptm)
  message("Data Loaded")

  # Data Cleaning -----------------------------------------------------------
  # Bind together and fix stadiums
  dat$game_dat <- bind_rows(dat$results, dat$fixture)
  
  dup_games <- dat$game_dat %>% select(Date, Home.Team, Away.Team) %>% duplicated()
  dat$game_dat <- dat$game_dat[!dup_games,]
  
  dat$game_dat <- dat$game_dat %>%
    mutate(Game = row_number()) %>%
    ungroup() %>%
    mutate(Venue = stringr::str_trim(Venue) %>% venue_fix()) %>%
    mutate(Round = Round.Number) 
  
  # ELO Prep
  last_n_games <- 100
  dat$game_dat <- elo_prep_calculations(dat$game_dat,
    states = dat$states,
    last_n_games = last_n_games
  )


  # Get results
  dat$results <- dat$game_dat %>%
    filter(!is.na(Home.Points))

  # Get fixture
  dat$fixture <- dat$game_dat %>%
    filter(is.na(Home.Points))

  # COVID Fix
  covid_seas <- last(dat$fixture$Round) < 23

  if (covid_seas) dat$fixture <- fix_covid_season(dat$fixture)

  print(proc.time() - ptm)
  message("Data Cleaned")

  # Run ELO calculation -----------------------------------------------------
  elo_dat <- run_elo(dat$results,
    carryOver = carryOver,
    B = B, e = e, d = d, h = h
  )

  dat$results <- elo_dat$results

  # Message
  print(proc.time() - ptm)
  message("ELO Run")

  # Predictions -------------------------------------------------------------
  # Do predictions
  dat$predictions <- do_elo_predictions(dat$fixture, elo_dat$elo.data)

  # Message
  print(proc.time() - ptm)
  message("Predictions Done")

  # Simulation --------------------------------------------------------------
  message("Simulating")
  sim_dat <- list()

  # do sims
  sim_dat <- append(
    sim_dat,
    do_sims(sim_num, dat$results, dat$fixture, elo_dat$elo.data)
  )

  # combine
  sim_dat$sim_data_all <- combine_sim_dat(sim_dat$sim_dat)

  if (new_season) {
    season <- last(dat$results$Season) + 1
    round <- 0
  } else {
    season <- last(dat$results$Season)
    round <- last(dat$results$Round)
  }

  # summarise
  sim_dat$sim_data_summary <- calculate_sim_perc(
    sim_dat$sim_data_all,
    season,
    round, sim_num
  )

  # Combine these simulations with previous ones for plotting
  # Load old sims
  past_sims <- read_rds(here::here("data_files", "raw-data", "AFLM_sims.rds"))
  combine_past_sims(sim_dat$sim_data_summary, round, season, past_sims)

  # Print to console
  sim_dat$sim_data_summary %>%
    filter(Round == round) %>%
    tail()

  sim_dat$simCount <- count_sims(
    sim_dat$sim_data_all,
    sim_dat$sim_data_summary,
    sim_num,
    season,
    round,
    past_sims
  )

  rm(past_sims)

  # MEssage
  print(proc.time() - ptm)
  message("Sims done")

  # Finals Sims -------------------------------------------------------------
  # source finals sims
  message("Doing Finals Sims")
  last_round <- last(dat$fixture$Round.Number)
  finals_dat <- do_finals_sims(
    sim_data_all = sim_dat$sim_data_all,
    game_dat = dat$game_dat,
    sim_num = sim_num,
    elo.data = elo_dat$elo.data,
    sim_elo_perterbed = sim_dat$sim_elo_perterbed,
    last_round = last_round
  )

  finals_dat <- combine_finals_sims(
    final_game = finals_dat$final_game,
    sim_data_summary = sim_dat$sim_data_summary,
    results = dat$results,
    elo.data = elo_dat$elo.data
  )

  print(proc.time() - ptm)
  message("Finals Sims done")

  # Save Data ---------------------------------------------------------------
  message("Saving data")
  # Create list
  aflm_data <- list(
    results = dat$results,
    elo.data = elo_dat$elo.data,
    elo = elo_dat$elo,
    predictions = dat$predictions
  )

  aflm_sims <- list(
    sim_data_summary = sim_dat$sim_data_summary,
    sim_data_all = sim_dat$sim_data_all,
    simCount = sim_dat$simCount
  )

  rm(sim_dat)
  rm(dat)

  # Save
  write_rds(finals_dat, path = here::here("data_files", "raw-data", "AFLM_finals_sims.rds"), compress = "bz")
  write_rds(aflm_data, path = here::here("data_files", "raw-data", "AFLM.rds"), compress = "bz")
  write_rds(aflm_sims, path = here::here("data_files", "raw-data", "AFLM_sims.rds"), compress = "bz")

  # Predictions
  predictions_csv <- aflm_data$predictions %>%
    select(Season, Date, Home.Team, Away.Team, Probability, Prediction)

  write_csv(aflm_data$predictions, path = here::here("data_files", "raw-data", "predictions.csv"))
  write_csv(predictions_csv, path = here::here("data_files", "raw-data", "predictions_new.csv"))

  # Writing csv
  write_csv(aflm_sims$sim_data_summary, path = here::here("data_files", "raw-data", "AFLM_sims_summary.csv"))
  write_csv(aflm_sims$simCount, path = here::here("data_files", "raw-data", "AFLM_sims_positions.csv"))
  write_csv(aflm_data$elo, path = here::here("data_files", "raw-data", "AFLM_elo.csv"))

  # Message
  print(proc.time() - ptm)
  message("Data saved")

  # Touch files ------------------------------------------------------------------
  blogdown:::touch_file(here::here("content", "page", "aflm-ratings-and-simulations.Rmd"))
  blogdown:::touch_file(here::here("content", "page", "aflm-current-tips.Rmd"))
  blogdown:::touch_file(here::here("content", "page", "aflm-predictions.Rmd"))
  blogdown:::touch_file(here::here("content", "page", "aflm-games.Rmd"))
}

print(proc.time() - ptm)
message("Finished!")
# blogdown:::serve_site()
# blogdown::hugo_build()
# blogdown::build_site()
