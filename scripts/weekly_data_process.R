# Script to run weekly updating of data, ratings simulations and predictions. Data should be saved into github for us by blog.
ptm <- proc.time()


# preamble ----------------------------------------------------------------
# Load libraries
library(fitzRoy)
library(tidyverse)
library(elo)
library(lubridate)
library(here)

# Set Parameters
HGA <- 36
B <- 0.025
k_val <- 18
carryOver <- 0.07
M <- 400


# Get Data ----------------------------------------------------------------
# Get fixture data using FitzRoy
fixture <- fitzRoy::get_fixture() %>%
  filter(Date > Sys.Date())

# Get results
results <- fitzRoy::get_match_results() %>%
  mutate(
    seas_rnd = paste0(Season, ".", Round.Number),
    First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
  )

# Get results_long
results_long <- convert_results(results)

# # Find distance and eperience for each venue
# results_long2 <- results_long %>%
#   group_by(Team) %>%
#   arrange(Team, Venue) %>%
#   mutate(Count = 1) %>%
#   mutate(roll = Venue == Venue)

# 
# tt <- as.Date("2000-01-01") + c(1, 2, 5, 6, 7, 8, 10)
# z <- zoo(seq_along(tt), tt)
# ## - fill it out to a daily series, zm, using NAs
# ## using a zero width zoo series g on a grid
# g <- zoo(, seq(start(z), end(z), "day"))
# zm <- merge(z, g)
# ## - 3-day rolling mean
# rollapply(zm, 3, mean, na.rm = TRUE, fill = NA)
#   

# Calculate ELO --------------------------------------------------------
# First some helper functions. These are used to adjust margin/outcome/k/HGA

# Squash margin between 0 and 1
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
calculate_hga <- function(experience, distance, e = 1, d = 1){
  (e * experience) +  (d * distance)
}

# calculate ELO using elo package.
elo.data <- elo.run(
  map_margin_to_outcome(Home.Points - Away.Points, B = B) ~
  adjust(Home.Team, HGA) +
    Away.Team +
    group(seas_rnd) +
    regress(First.Game, 1500, carryOver) +
    k(calculate_k(Home.Points - Away.Points, k_val)),
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


# Simulation --------------------------------------------------------------
res <- results %>%
  filter(year(Date) == year(Sys.Date())) %>%
  mutate(
    Season.Game = Game - min(Game) + 1,
    Round = Round.Number
  )

remaining_fixture <- fixture %>%
  mutate(Date = mdy(format(Date[1], "%D")))

# Get ELOS and perturb them
form <- elo:::clean_elo_formula(stats::terms(elo.data)) # needed for elo.prob
perturb_elos <- function(x) final.elos(x) + rnorm(length(x$teams), mean = 0, sd = 65) # function to map over

# Do simulations
sims <- 1:10000

# First replicate results
res <- sims %>%
  map_df(~mutate(res, Sim = .x))

# Now simulate
sim_data <- sims %>%
  rep_along(list(elo.data)) %>%
  map(perturb_elos) %>%
  map(~ elo.prob(form, data = remaining_fixture, elos = .x)) %>%
  map2_df(sims, ~ mutate(
    remaining_fixture, Probability = .x,
    Margin = ceiling(map_outcome_to_margin(Probability)),
    Sim = .y
  )) %>%
  bind_rows(res)


# Summarise simulated data
win_calc <- function(x) case_when(x == 0 ~ 0.5, x > 0 ~ 1, TRUE ~ 0)

sim_data_all <- sim_data %>%
  gather(Status, Team, Home.Team:Away.Team) %>%
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
  summarise(
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
past_sims <- read_rds(here("data", "raw-data", "AFLM.rds"))

# Bind with last entry
sim_data_summary <- past_sims$sim_data_summary %>%
  bind_rows(sim_data_summary)
  
# Predictions -------------------------------------------------------------
# Do predictions
predictions <- fixture %>%
  mutate(
    Day = format(Date, "%a, %d"),
    Time = format(Date, "%H:%M"),
    Probability = round(predict(elo.data, newdata = fixture), 3),
    Prediction = ceiling(map_outcome_to_margin(Probability)),
    Result = case_when(
      Probability > 0.5 ~ paste(Home.Team, "by", Prediction),
      Probability < 0.5 ~ paste(Away.Team, "by", -Prediction),
      TRUE ~ "Draw"
    )
  ) %>%
  select(Day, Time, Round, Venue, Home.Team, Away.Team, Prediction, Probability, Result)


# Save Data ---------------------------------------------------------------
# Create list
aflm_data <- list(
  elo.data = elo.data, 
  elo = elo, 
  predictions = predictions)

aflm_sims <- list(
  sim_data_all = sim_data_all,
  sim_data_summary = sim_data_summary
)

# Save
write_rds(aflm_data, path = here("data", "raw-data", "AFLM.rds"), compress = "bz")
write_rds(aflm_sims, path = here("data", "raw-data", "AFLM_sims.rds"), compress = "bz")

# Clean up large files
rm(elo.data, sim_data, aflm_sims, aflm_data)
print(proc.time() - ptm)
