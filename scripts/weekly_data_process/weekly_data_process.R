# Script to run weekly updating of data, ratings simulations and predictions. Data should be saved into github for us by blog.
ptm <- proc.time()
set.seed(42)
message("Starting Script")
# Preamble ----------------------------------------------------------------
# Load libraries
library(fitzRoy)
library(pacman)
pacman::p_load(tidyverse, elo, here, lubridate, tibbletime)

# source functions
source(here::here("scripts", "weekly_data_process", "0-functions.R"))
source(here::here("scripts", "weekly_data_process", "0a-check-data.R"))
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
season <- 2023
new_season <- FALSE
save_data <- TRUE

# Set ELO Parameters
e <- 1.7
d <- -32
h <- 20
k_val <- 20
carryOver <- 0.5
B <- 0.04
sim_num <-  10000

# Check Data ----------------------------------------------------------------

# First check if new results exist
new_results <- check_results(season)
new_fixture <- check_fixture(season)

if(new_results | new_fixture | new_season) {
  message("New data found")
  new_data <- TRUE
} else{
  message("No new data found")
  new_data <- FALSE
}


# Manual override
# new_data <- TRUE

# Get Data ----------------------------------------------------------------
if (new_data) {
  dat <- get_data(season,
                  filt_date,
                  grand_final_bug = grand_final_bug,
                  fixture_bug = fixture_bug
  )
  
  # check if home and away season is done
  home_away_ongoing <- any(dat$fixture$status != "CONCLUDED" & !dat$fixture$Finals)
  finals_started <- any(dat$fixture$status == "CONCLUDED" & dat$fixture$Finals)
  finals_scheduled <- any(dat$fixture$Finals)
  
  print(proc.time() - ptm)
  message("Data Loaded")
  
  # Data Cleaning -----------------------------------------------------------
  # Bind together and fix stadiums
  # Fixture is broken, lets see if removing round helps
  #dat$fixture$Round = NA
  dat$fixture <- dat$fixture %>% filter(status != "CONCLUDED")
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
  
  dat$game_dat <- dat$game_dat %>%
    mutate(Home.Interstate = ifelse(is.na(Home.Interstate), FALSE, Home.Interstate),
           Away.Interstate = ifelse(is.na(Away.Interstate), FALSE, Away.Interstate))
  
  # Get results
  dat$results <- dat$game_dat %>%
    filter(!is.na(Home.Points))
  
  # Get fixture
  dat$fixture <- dat$game_dat %>%
    filter(is.na(Home.Points))
  
  
  season_complete <- nrow(dat$fixture) == 0 &  
    last(dat$results$Round.Type == "Finals") &
    last(dat$results$Round.Number > 26)
    
  # COVID Fix
  covid_seas <- last(dat$fixture$Round) < 18
  
  if (covid_seas & !season_complete) dat$fixture <- fix_covid_season(dat$fixture)
  
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
  
  # In season stuff --------------------------------------------------------
  if (!season_complete){
  # Predictions ------------------------------------------------------------

    # Do predictions
    
    dat$predictions <- do_elo_predictions(dat$fixture, elo_dat$elo.data, carryOver, new_season)
    
    # Message
    print(proc.time() - ptm)
    message("Predictions Done")
    
  }
  

  # Simulation --------------------------------------------------------------
  # Skip if home_away has finished
  if (home_away_ongoing) {
    
    message("Doing In Season Simulations...")
    sim_dat <- list()
    
    # do sims
    sim_dat <- append(
      sim_dat,
      do_sims(sim_num, dat$results, dat$fixture, elo_dat$elo.data)
    )
    
    # combine
    res <- dat$results %>% filter(Season == season)
    if (nrow(res) == 0) res <- NULL
    sim_dat$sim_data_all <- combine_sim_dat(sim_dat$sim_data, res)
    
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
    
    sim_dat$simCount <- count_sims(
      sim_dat$sim_data_all,
      sim_dat$sim_data_summary,
      sim_num,
      season,
      round,
      past_sims
    )
    
    simWins <- 
      sim_dat$sim_data_summary %>%
      arrange(Wins)
    #rm(past_sims)
    
    # MEssage
    print(proc.time() - ptm)
    message("In Season Sims done")
  }
  
  # Finals Sims -------------------------------------------------------------
  # source finals sims
  if (!season_complete){
    
  
  if (home_away_ongoing) {
    message("Doing Finals Sims H&A")
    last_round <- last(dat$fixture$Round.Number)
    
    finals_sims <- do_finals_sims(
      sim_data_all = sim_dat$sim_data_all,
      game_dat = dat$game_dat,
      sim_num = sim_num,
      elo.data = elo_dat$elo.data,
      sim_elo_perterbed = sim_dat$sim_elo_perterbed,
      last_round = last_round
    )
    
    finals_dat <- combine_finals_sims(
      final_game = finals_sims$final_game,
      sim_data_summary = sim_dat$sim_data_summary,
      results = dat$results,
      elo.data = elo_dat$elo.data,
      sim_num = sim_num,
      ladder = dat$ladder
    )
    
    finals_dat$home_away_ongoing <- home_away_ongoing
  }
  
  if (finals_scheduled | finals_started) {
    message("Doing Finals Sims In Finals")
    final_sim_num <- 1000
    sim_dat <- read_rds(here::here("data_files", "raw-data", "AFLM_sims.rds"))
    finals_results <- dat$results %>% 
      filter(Season == season & Round.Type == "Finals")
    
    finals_weeks_completed <- length(unique(finals_results$Round))
    last_round <- last(dat$fixture$Round.Number)
    
    finals_sims <- do_finals_sims(sim_data_all = sim_dat$sim_data_all, 
                                  game_dat = dat$game_dat, 
                                  sim_num = final_sim_num,
                                  elo.data = elo_dat$elo.data,
                                  sim_elo_perterbed = NULL,
                                  last_round = last_round,
                                  ladder = dat$ladder,
                                  finals_started = finals_started,
                                  finals_week = finals_weeks_completed,
                                  finals_results = finals_results)
    
    finals_dat <- combine_finals_sims(
      final_game = finals_sims$final_game,
      sim_data_summary = sim_dat$sim_data_summary,
      results = dat$results,
      elo.data = elo_dat$elo.data,
      sim_num = final_sim_num,
      ladder = dat$ladder,
      home_and_away_complete = TRUE
    )
    
    finals_dat$home_away_ongoing <- home_away_ongoing
    
  }
  
  
  
  print(proc.time() - ptm)
  message("Finals Sims done")
  }
  # Save Data ---------------------------------------------------------------
  
  if(save_data) {
    
    
    message("Saving data")
    # Create list
    aflm_data <- list(
      results = dat$results,
      elo.data = elo_dat$elo.data,
      elo = elo_dat$elo,
      predictions = dat$predictions
    )
    
    # Save data
    
    write_rds(aflm_data, file = here::here("data_files", "raw-data", "AFLM.rds"), compress = "bz")
    write_csv(aflm_data$results, file = here::here("data_files", "processed-data", "AFLM_results.csv"))
    # Save Predictions
    if (!season_complete) {
      
    
    predictions_csv <- aflm_data$predictions %>%
      select(Season, Date, Home.Team, Away.Team, Probability, Prediction)
    write_csv(aflm_data$predictions, file = here::here("data_files", "raw-data", "predictions.csv"))
    write_csv(predictions_csv, file = here::here("data_files", "raw-data", "predictions_new.csv"))
    write_csv(aflm_data$predictions, file = here::here("data_files", "processed-data", "AFLM_predictions.csv"))
    }
    
    # Save elo
    write_csv(aflm_data$elo, file = here::here("data_files", "raw-data", "AFLM_elo.csv"))
    write_csv(aflm_data$elo, file = here::here("data_files", "processed-data", "AFLM_elo.csv"))
    #elo <- read_csv(here::here("data_files", "raw-data", "AFLM_elo.csv"))
    elo <- aflm_data$elo
    
    current_elo <- elo %>% 
      group_by(Team) %>% 
      filter(Game == max(Game)) %>%
      filter(Game > 16000) %>%
      arrange(desc(ELO)) %>%
      mutate(ELO_change = ELO - ELO_pre,
             Season = format(Date, "%Y")) %>%
      select(Team, Date, Game, Season, Round, ELO, ELO_pre, ELO_change) %>%
      mutate(Updated = Sys.time())
    
    write_csv(current_elo, file = here::here("data_files", "raw-data", "current_elo.csv"))
    
    # Save sims
    if (!season_complete) {
      
    
    if (home_away_ongoing | finals_scheduled | finals_started) {
      aflm_sims <- list(
        sim_data_summary = sim_dat$sim_data_summary,
        sim_data_all = sim_dat$sim_data_all,
        simCount = sim_dat$simCount
      )
      
      
      # Save data
      write_rds(aflm_sims, 
                file = 
                  here::here("data_files", "raw-data", "AFLM_sims.rds"), 
                compress = "bz")
      
      # Writing csv
      write_csv(aflm_sims$sim_data_summary, 
                file = here::here("data_files", "raw-data", "AFLM_sims_summary.csv"))
      write_csv(aflm_sims$simCount, 
                file = 
                  here::here("data_files", "raw-data", "AFLM_sims_positions.csv"))
      
      write_csv(finals_dat$sims_combined,
                file = here::here("data_files", "processed-data", "AFLM_sims_combined.csv"))
      
      write_csv(data.frame(home_away_ongoing =finals_dat$home_away_ongoing),
                file = here::here("data_files", "processed-data", "AFLM_home_away_ongoing.csv"))
      
      # Save finals
      write_rds(finals_dat, 
                file = here::here("data_files", "raw-data", "AFLM_finals_sims.rds"), compress = "bz")
      
    }
    }
    
    # Message
    print(proc.time() - ptm)
    message("Data saved")
  }
  
  # Touch files ------------------------------------------------------------------
  #blogdown:::touch_file(here::here("content", "page", "aflm-ratings-and-simulations.Rmd"))
  #blogdown:::touch_file(here::here("content", "page", "aflm-current-tips.Rmd"))
  #blogdown:::touch_file(here::here("content", "page", "aflm-predictions.Rmd"))
  #blogdown:::touch_file(here::here("content", "page", "aflm-games.Rmd"))
}

print(proc.time() - ptm)
message("Finished!")

