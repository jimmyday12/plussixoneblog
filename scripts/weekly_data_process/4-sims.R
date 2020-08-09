
perturb_elos <- function(x) {
  x <- final.elos(x) + rnorm(length(x$teams), mean = 0, sd = 65)
  x + 1500 - mean(x)
} # function to map over


do_sims <- function(sim_num, results, fixture, elo.data){
  
  #pb <- progress_bar$new(total = sim_num)
  
  sim_res <- results %>%
    filter(year(Date) == min(fixture$Season)) %>%
    mutate(
      Season.Game = Game - min(Game) + 1,
      Round = Round.Number
    )
  
  remaining_fixture <- fixture
  
  # Get ELOS and perturb them
  form <- elo:::clean_elo_formula(stats::terms(elo.data)) # needed for elo.prob
  
  # Do simulations
  #sims <- 1:5
  sims <- 1:sim_num
  
  res <- sims %>%
    map_df(~mutate(sim_res, Sim = .x))
  
  # Now simulate
  sim_elo_perterbed <- sims %>%
    rep_along(list(elo.data)) %>%
    map(perturb_elos) 
  
  sim_data <- sim_elo_perterbed %>%
    map(~elo.prob(form, data = remaining_fixture, elos = .x)) %>%
    map2_df(sims, ~mutate(
      remaining_fixture, Probability = .x,
      Margin = ceiling(map_outcome_to_margin(Probability, B = B)),
      Sim = .y)) %>%
    bind_rows(res)

  list(sim_data = sim_data,
       sim_elo_perterbed = sim_elo_perterbed)
}


# Summarise simulated data
win_calc <- function(x) case_when(x == 0 ~ 0.5, x > 0 ~ 1, TRUE ~ 0)

combine_sim_dat <- function(sim_data) {
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
    Top.2 = Rank < 3,
    Top.1 = Rank == 1
  )

}

calculate_sim_perc <- function(sim_dat_all, season, round, sim_num){


# Summarise the simulations into percentages
sim_data_summary <- sim_dat_all %>%
  group_by(Team) %>%
  dplyr::summarise(
    Season = season,
    Round = round,
    Margin = mean(Margin),
    Wins = mean(Wins),
    Top.8 = sum(Top.8) / sim_num,
    Top.4 = sum(Top.4) / sim_num,
    Top.2 = sum(Top.2) / sim_num,
    Top.1 = sum(Top.1) / sim_num
  )
}


combine_past_sims <- function(sim_data_summary, round, season, past_sims){
  
# Combine these simulations with previous ones for plotting
# Load old sims


# Bind with last entry
sim_data_summary <- past_sims$sim_data_summary %>%
  filter(!(Round == round  & 
             Season == season)) %>%
  bind_rows(sim_data_summary)

}

count_sims <- function(sim_data_all, sim_data_summary, sim_num, season, round, past_sims) {
# Count finishing position probability
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
  filter(Season == season) %>%
  filter(Round == round) %>%
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
    filter(!(Round == round  & 
               Season == season)) %>%
    bind_rows(simCount)
}
}
