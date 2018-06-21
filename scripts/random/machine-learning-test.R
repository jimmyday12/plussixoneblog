# Script to run weekly updating of data, ratings simulations and predictions. Data should be saved into github for us by blog.
ptm <- proc.time()

# preamble ----------------------------------------------------------------
# Load libraries
library(pacman)
pacman::p_load(fitzRoy, tidyverse, elo, here, lubridate, tibbletime, caret, recipe)

# Set Parameters
e <- 1.7
d <- -32
h <- 20
k_val <- 20
carryOver <- 0.05
B <- 0.04
sim_num <- 10000

# Get Data ----------------------------------------------------------------
filt_date <- Sys.Date() + 1
# Get fixture data using FitzRoy
fixture <- fitzRoy::get_fixture() %>%
  filter(Date > filt_date) %>%
  mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
  rename(Round.Number = Round)

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
    x == "Blundstone Arena" ~ "Bellerive Oval",
    x == "GMHBA Stadium" ~ "Kardinia Park",
    x == "Spotless Stadium" ~ "Blacktown",
    x == "UTAS Stadium" ~ "York Park",
    x == "Mars Stadium" ~ "Eureka Stadium",
    x == "Adelaide Arena at Jiangwan Stadium" ~ "Jiangwan Stadium",
    x == "TIO Traegar Park" ~ "Traeger Park",
    x == "Metricon Stadium" ~ "Carrara",
    x == "TIO Stadium" ~ "Marrara Oval",
    x == "Optus Stadium" ~ "Perth Stadium",
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
  log((1 / outcome) - 1) / - B
}

# Function to calculate k (how much weight we add to each result)
calculate_k <- function(margin, k_val, round) {
  mult <- (log(abs(margin) + 1) - log(round))
  k_val * ifelse(mult <= 0, 1, mult)
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

## Machine Learning Stuff
dat <- results %>%
  bind_cols(as.data.frame(elo.data)) %>%
  mutate(Home.elo = elo.A - update - 1500,
         Away.elo = elo.B + update - 1500,
         Home.Venue.Exp = Home.Venue.Exp / 100,
         Away.Venue.Exp = Away.Venue.Exp / 100,
         Home.Result = case_when(
           Margin > 0 ~ "Win",
           Margin < 0 ~ "Lose")) %>%
  select(Round.Number, Margin, Home.Venue.Exp:Away.Interstate, Home.elo, Away.elo, Home.Result) %>%
  mutate_if(is.logical, as.numeric) %>% 
  bind_cols(select(results, Date)) %>%
  filter(!is.na(Home.Result))

train <- dat %>%
  filter(Date < ymd("2017-01-01") & Date > ymd("1990-01-01"))  %>%
  select(-Date, -Home.Result)

test <- dat %>%
  filter(Date >= ymd("2017-01-01")) %>% 
  select(-Date, -Home.Result)

model_recipe <- recipe(Margin ~ ., data = train) %>%
  step_scale(contains("elo"))

# Train recipe
trained_recipe <- prep(model_recipe, data = train)
train_data <- bake(trained_recipe, newdata = train) 
test_data <- bake(trained_recipe, newdata = test) 


set.seed(42)


maeSummary <- function (data,
                        lev = NULL,
                        model = NULL) {
  
  require(Metrics)
  out <- mae(data$obs, data$pred)  
  names(out) <- "MAE"
  out
}

mControl <- trainControl(summaryFunction = maeSummary)

lm_model <- train(Margin ~ ., 
                  data = train_data, 
                  method = "lm",
                  metric = "MAE",
                  maximize = FALSE,
                  trControl = mControl)
lm_model
  plot(lm_model)
summary(lm_model)

preds <- predict(lm_model,
              newdata = test_data)

test_data_pred <- test_data %>%
  bind_cols(pred = preds) %>%
  mutate(abs_err = abs(Margin - preds))

mean(test_data_pred$abs_err)
sum(sign(test_data_pred$pred) == sign(test_data_pred$Margin))

elo_pred <- results %>%
  filter(Date >= ymd("2017-01-01")) %>%
  mutate(abs_err = abs(Margin - Prediction))

mean(elo_pred$abs_err)
sum(sign(elo_pred$Prediction) == sign(elo_pred$Margin))

## Quick test with no resampling or tuning
# ELO = 28.30128 #208
# glmnet = 29.27888 #200
# lm = 29.36881 #199
# nnet = 33
# blassoAveraged = 28.30128 #196
# rf = 28.7439 #202
# svmLinear = 29.26819 #199
# xgbLinear = 30.19399 #202


