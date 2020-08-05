# Finals Sims
library(tidyverse)
# get data
aflm_data <- read_rds(here::here("data_files", "raw-data", "AFLM.rds"))
aflm_sims <- read_rds(here::here("data_files", "raw-data", "AFLM_sims.rds"))
aflm_finals_data <- aflm_finals_data

sim_num <- aflm_finals_data$sim_num

# Helper functions ---------------
create_finals_fixture <- function(week = 1, season, last_game_num, last_round) {
  if(week == 1) {
    dat <- tibble(
      Game = (last_game_num+1):(last_game_num+4),
      Game_Name = c("QF1", "QF2", "EF1", "EF2"))
  }
  
  if(week == 2){
    dat <- tibble(
      Game = (last_game_num+1):(last_game_num+2),
      Game_Name = c("SF1", "SF2"))
  }
  if(week == 3){
    dat <- tibble(
      Game = (last_game_num+1):(last_game_num+2),
      Game_Name = c("PF1", "PF2"))
  }
  
  if(week == 4){
    dat <- tibble(
      Game = (last_game_num+1),
      Game_Name = c("GF"))
  }
  
  dat %>%
    mutate(Season = season,
           Finals_week = week,
           Round = last_round + week)
}

simulate_finals <- function(form, fixture, elos, sim_num){
  probs <- elos %>%
    map2(.y = fixture, 
         .f =  ~elo::elo.prob(form, data = .y, elos = .x))
  
  map2(.x = fixture, 
       .y = probs, 
       .f = ~mutate(.x, 
                    Probability = .y,
                    Margin = ceiling(map_outcome_to_margin(Probability, B = B)),
                    Win = rbinom(n(), 1, Probability))) %>%
    map2(.y = 1:sim_num,
         ~mutate(.x, 
                 Sim = .y)) 
}

add_formula_variables <- function(fixture) {
  fixture %>%
        mutate(Venue = "",
               Home.Venue.Exp = 1,
               Away.Venue.Exp = 1,
               Home.Interstate = FALSE,
               Away.Interstate = FALSE,
               Home.Factor = 1,
               Away.Factor = 0)
}


# Add elo
form <- elo:::clean_elo_formula(stats::terms(aflm_data$elo.data))

finals_elos <- aflm_finals_data$sim_elo_perterbed[1:sim_num]

# Week 1 -----------------------------------------------------------------------
# Step 1 - get top 8
sim_ladder <- aflm_sims$sim_data_all %>%
  filter(Top.8) %>%
  arrange(Sim, Rank) %>%
  group_by(Sim) %>%
  select(Sim, Team, Rank) %>%
  group_split() %>%
  .[1:sim_num]

# Step 2 - create fixture
game_dat <-  aflm_finals_data$game_dat
wk1_fixture <- create_finals_fixture(week = 1, 
                                        season = last(game_dat$Season),
                                        last_game_num = last(game_dat$Game),
                                        last_round = aflm_finals_data$last_round)


# Step 3 - get the right teams
wk1_fixture <- sim_ladder %>%
  map(~wk1_fixture %>%
        mutate(Home.Team = .x$Team[c(1,2,5,6)],
               Away.Team = .x$Team[c(4,3,8,7)]))

# Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
wk1_fixture <- wk1_fixture %>%
  map(add_formula_variables)
  
# Step 5 - simulate results
wk1_results <- simulate_finals(form, wk1_fixture, finals_elos, sim_num)


# Week 2 -----------------------------------------------------------------------
# Step 1 - get week 2 teams
wk2_teams <- wk1_results %>%
map(~mutate(.x,
            Winner = ifelse(Win == 1, Home.Team, Away.Team),
             Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
              select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  
# Step 2 - create fixture
wk2_fixture <- create_finals_fixture(week = 2, 
                                     season = last(wk1_results[[1]]$Season),
                                     last_game_num = last(wk1_results[[1]]$Game),
                                     last_round = last(wk1_results[[1]]$Round))


# Step 3 - get the right teams
wk2_fixture <- wk2_teams %>%
  map(~wk2_fixture %>%
        mutate(Home.Team = .x$Loser[c(which(.x$Game_Name == "QF1"), which(.x$Game_Name == "QF2"))],
               Away.Team = .x$Winner[c(which(.x$Game_Name == "EF1"), which(.x$Game_Name == "EF2"))]))

# Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
wk2_fixture <- wk2_fixture %>%
  map(add_formula_variables)


# Step 5 - simulate results
wk2_results <- simulate_finals(form, wk2_fixture, finals_elos, sim_num)

# Week 3 -----------------------------------------------------------------------
# Step 1 - get week 2 teams
wk3_teams <- wk2_results %>%
  map2(.y = wk2_teams, 
       ~mutate(.x,
              Winner = ifelse(Win == 1, Home.Team, Away.Team),
              Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
        select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
  bind_rows(.y))

# Step 2 - create fixture
wk3_fixture <- create_finals_fixture(week = 3, 
                                     season = last(wk2_results[[1]]$Season),
                                     last_game_num = last(wk2_results[[1]]$Game),
                                     last_round = last(wk2_results[[1]]$Round))


# Step 3 - get the right teams
wk3_fixture <- wk3_teams %>%
  map(~wk3_fixture %>%
        mutate(Home.Team = .x$Winner[c(which(.x$Game_Name == "QF1"), which(.x$Game_Name == "QF2"))],
               Away.Team = .x$Winner[c(which(.x$Game_Name == "SF2"), which(.x$Game_Name == "SF1"))]))

# Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
wk3_fixture <- wk3_fixture %>%
  map(add_formula_variables)


# Step 5 - simulate results
wk3_results <- simulate_finals(form, wk3_fixture, finals_elos, sim_num)



# Week 4 -----------------------------------------------------------------------
# Step 1 - get week 2 teams
wk4_teams <- wk3_results %>%
  map2(.y = wk3_teams, 
       ~mutate(.x,
               Winner = ifelse(Win == 1, Home.Team, Away.Team),
               Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
         select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
         bind_rows(.y))

# Step 2 - create fixture
wk4_fixture <- create_finals_fixture(week = 4, 
                                     season = last(wk3_results[[1]]$Season),
                                     last_game_num = last(wk3_results[[1]]$Game),
                                     last_round = last(wk3_results[[1]]$Round))


# Step 3 - get the right teams
wk4_fixture <- wk4_teams %>%
  map(~wk4_fixture %>%
        mutate(Home.Team = .x$Winner[c(which(.x$Game_Name == "PF1"))],
               Away.Team = .x$Winner[c(which(.x$Game_Name == "PF2"))]))

# Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
wk4_fixture <- wk4_fixture %>%
  map(add_formula_variables)


# Step 5 - simulate results
wk4_results <- simulate_finals(form, wk4_fixture, finals_elos, sim_num)

# Combine and sunmmarise -------------------------------------------------------
final_teams <- wk4_results %>%
  map2(.y = wk4_teams, 
       ~mutate(.x,
               Winner = ifelse(Win == 1, Home.Team, Away.Team),
               Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
         select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
         bind_rows(.y))

final_results <- final_teams %>%
  map(~.x %>%
  pivot_longer(c(Winner, Loser),
               names_to = "Result",
               values_to = "Team") %>%
  group_by(Team) %>%
  mutate(max_week = max(Finals_week)))

final_game <- final_results %>%
  map(~.x %>%
  filter(max_week == Finals_week) %>%
  mutate(Game = str_remove(Game_Name, "[0-9]"),
         Game = ifelse(Game == "GF" & Result == "Winner", "Premier", Game)) %>%
  select(Season, Team, Game, Finals_week, Sim))

# Summarise across all
final_summary_long <- bind_rows(final_game)
final_summary_wide <- final_summary_long %>%
  group_by(Season, Team) %>%
  summarise(
    win_league = sum(Game == "Premier"),
    make_gf = sum(Game == "GF") + win_league,
    make_prelim = sum(Game == "PF") + make_gf,
    make_semis = sum(Game == "SF") + make_prelim,
    make_finals = n()
    ) %>%
  mutate_if(is.numeric, ~./sim_num) %>%
  mutate_all(replace_na, 0)


season_sims <- aflm_sims$sim_data_summary %>%
  filter(Season == max(final_summary_wide$Season)) %>%
  filter(Round == max(Round))

sims_combined <- season_sims %>%
  left_join(final_summary_wide, by = c("Team", "Season"))
    
sims_combined


# Add elo
elos <- aflm_data$elo.data %>% 
  final.elos() %>% 
  as.data.frame() %>%
  rownames_to_column("Team")
elos$elo <- elos$.
elos <- elos %>%
  select(Team, elo)

elos <- aflm_data$elo.data %>% 
  as.matrix() %>% 
  tail(2) %>% 
  t() %>%
  as.data.frame() %>%
  rownames_to_column("Team")

names(elos) <- c("Team", "elo.old", "elo") 

elos <- elos %>% 
  mutate(elo.change = elo - elo.old)

sims_combined <- sims_combined %>%
  left_join(elos) %>%
  mutate_all(replace_na, 0)


# Get current results
res <- aflm_finals_data$results
res <- res %>% 
  filter(Season == max(sims_combined$Season)) %>%
  select(Season, Home.Team, Away.Team, Home.Points, Away.Points, Round) %>%
  mutate(Margin = Home.Points - Away.Points,
         Home.Result = case_when(Margin > 0 ~ 1,
                                  Margin < 0 ~ 0,
                                  TRUE ~ 0.5))

win_loss <- res %>%
  pivot_longer(cols = c("Home.Team", "Away.Team"),
               names_to = "Status", 
               values_to = "Team") %>%
  mutate(Result = ifelse(Status == "Home.Team", Home.Result, 1-Home.Result)) %>%
  select(Season, Team, Round, Result) %>%
  group_by(Team, Season) %>%
  mutate(Wins = ifelse(Result == 1, 1, 0),
         Losses = ifelse(Result == 0, 1, 0),
         Draws = ifelse(Result == 0.5, 1, 0)) %>%
  summarise(Wins = sum(Wins),
            Losses = sum(Losses),
            Draws = sum(Draws)) %>%
  mutate(Form = ifelse(Draws > 0, 
                       paste0(Wins, "-", Losses, "-", Draws),
                       paste0(Wins, "-", Losses)))

sims_combined <- sims_combined %>%
  left_join(select(win_loss, Team, Season, Form), by = c("Team", "Season"))

aflm_finals_sims <- list(sims_combined = sims_combined,
                         win_loss = win_loss)
write_rds(aflm_finals_sims, path = here::here("data_files", "raw-data", "AFLM_finals_sims.rds"), compress = "bz")

