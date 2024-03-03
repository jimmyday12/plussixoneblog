# New model
library(tidymodels)
library(tidyverse)
library(fitzRoy)
library(RcppRoll)
library(zoo)
library(vip)

set.seed(42)
seasons <- 2015:2023

# Get Raw Data -----------------------------------------------------------------
# ELOS
dat <- read_rds(here::here("data_files", "raw-data", "AFLM.rds"))
elo_dat <- dat$elo

venue_dat <- dat$results |> 
  select(Date, Round, Home.Team, Away.Team, Home.Venue.Exp, Home.Interstate, Away.Venue.Exp, Away.Interstate)

# Results
#results <- seasons |> 
#  purrr::map_dfr(fetch_results_afl)
#write_rds(results, here::here("data_files", "raw-data", 'results.rds'))

results <- read_rds(here::here("data_files", "raw-data", 'results.rds'))

#stats <- seasons |> 
#  purrr::map_dfr(fetch_player_stats_afl)
#write_rds(stats, here::here("data_files", "raw-data", "stats.rds"))


# Stats
stats <- read_rds(here::here("data_files", "raw-data", "stats.rds"))

stats_clean <- stats |> 
  mutate(home_team = ifelse(home.team.name == team.name, TRUE, FALSE)) |> 
  rename_with(str_remove, starts_with("extendedStats"), "^extendedStats.") |> 
  rename_with(str_remove, starts_with("player"), "^player.") 



# Create Summary Data ------------------------------------------------------
# Player Ratings ---------
n_cutoff <- 23
player_stats <- stats_clean |> 
  select(providerId, utcStartTime, round.name, teamId, playerId, player.player.surname, ratingPoints) |> 
  group_by(playerId) |> 
  arrange(utcStartTime, .by_group = TRUE) |> 
  mutate(game_no = row_number())

first_year_stats <- player_stats |> 
  filter(game_no < n_cutoff) 

first_year_mean <- mean(first_year_stats$ratingPoints, na.rm = TRUE)

player_rp <- player_stats |> 
  mutate(ratingPoints_lag = lag(ratingPoints)) |> 
  mutate(ratingPoints_roll = rollmean(ratingPoints_lag, 
                                      k=100, fill = NA, 
                                      partial = TRUE, 
                                      na.rm = TRUE, 
                                      align = 'right')) |> 
  drop_na() |> 
  mutate(ratingPoints_mean =
           ifelse(game_no < n_cutoff, 
                  (ratingPoints_roll * game_no + (n_cutoff - game_no ) * first_year_mean) / n_cutoff, 
                  ratingPoints_roll)) |> 
  select(providerId, utcStartTime, teamId, playerId, ratingPoints_mean)

team_rp <- player_rp |> 
  group_by(providerId, teamId) |> 
  summarise(ratingPoints_selected = mean(ratingPoints_mean))

# Stats ----
stats_team <- stats_clean |> 
  select(providerId, teamId, team.name, home_team,
         utcStartTime, round.roundNumber, 
         goals, behinds, kicks:ratingPoints,
         turnovers:metresGained,
         contains("extendedStats"),
         -contains("centreBounceAttendances"), -contains("kickins")) |> 
  group_by(providerId,utcStartTime, round.roundNumber, teamId, team.name, home_team) |> 
  summarise(across(contains(c("Efficiency", "Rate", "Percentage", "Ratio", "Accuracy")), mean),
            across(!contains(c("Efficiency", "Rate", "Percentage", "Accuracy", "Ratio")), sum)) |> 
  select(where(~ !all(is.na(.)))) |> 
  arrange(team.name, utcStartTime)  |> 
  mutate(round.roundNumber = as.character(round.roundNumber)) 

stats_team_score <- stats_team |> 
  mutate(score_for = goals * 6 + behinds) |> 
  group_by(providerId) |> 
  arrange(utcStartTime, providerId, desc(home_team)) |> 
  mutate(score_against = ifelse(home_team, last(score_for), first(score_for))) |> 
  mutate(win = case_when(
    score_for > score_against ~ 1,
    score_for < score_against ~ 0,
    .default = 0.5
  ))

# Rolling averages per team
stats_lag <- stats_team_score |> 
  group_by(team.name) |> 
  arrange(team.name, utcStartTime)  |> 
  mutate(across(where(is.numeric), ~lag(.)))

stats_roll <- stats_lag |> 
  mutate(across(where(is.numeric), ~rollmean(., k=5, fill=NA, align='right'))) |> 
  ungroup() |> 
  mutate(percentage_l5 = ((score_for * 5) / (score_against * 5)) * 100) |> 
  mutate(wins_l5 = win * 5)

stats_game_diff <- stats_roll |> 
  group_by(providerId) |> 
  arrange(utcStartTime, providerId, desc(home_team)) |> 
  mutate(across(where(is.numeric), ~.x - lead(.x), .names = "{.col}_diff")) |> 
  filter(home_team) |> 
  select(providerId, contains("_diff")) |> 
  drop_na()

# ELO ----
replace_teams <- function(Team) {
  case_when(
    Team == "Adelaide" ~ "Adelaide Crows", 
    Team == "Footscray" ~ "Western Bulldogs",
    Team == "Geelong" ~ "Geelong Cats",
    Team == "Gold Coast" ~ "Gold Coast Suns",
    Team == "GWS" ~ "GWS Giants",
    Team == "Sydney" ~ "Sydney Swans", 
    Team == "West Coast" ~ "West Coast Eagles",
    .default = Team)
}

elo_simple <- elo_dat |> 
  select(round.year, Round.Number, Team, ELO_pre) |> 
  mutate(Team = replace_teams(Team),
         round.year = format(Date, "%Y")) |> 
  rename(round.roundNumber = Round.Number)

# Venue ----
venue_simple <- venue_dat |> 
  mutate(match.homeTeam.name = replace_teams(Home.Team),
         match.awayTeam.name = replace_teams(Away.Team),
         round.year = format(Date, "%Y"),
         across(contains("Interstate"), as.numeric)) |> 
  rename(round.roundNumber = Round) |> 
  select(-Date, -Away.Team, -Home.Team)

# Combine Data -----------------------------------------------------------------

# Add ELO and Result
final_dat <- results |> 
  mutate(margin = homeTeamScore.matchScore.totalScore - awayTeamScore.matchScore.totalScore) |> 
  select(match.name, match.date, match.matchId,
         match.homeTeamId, match.awayTeamId,
         match.homeTeam.name, match.awayTeam.name, round.year, round.roundNumber,
         margin,
         homeTeamScore.matchScore.totalScore, 
         awayTeamScore.matchScore.totalScore) |> 
  left_join(elo_simple, by = join_by(round.year, round.roundNumber, match.homeTeam.name == Team)) |> 
  rename(home_elo = ELO_pre) |> 
  left_join(elo_simple, by = join_by(round.year, round.roundNumber, match.awayTeam.name == Team)) |> 
  rename(away_elo = ELO_pre) |> 
  left_join(venue_simple, by = join_by(round.year, round.roundNumber, match.homeTeam.name, match.awayTeam.name)) |> 
  left_join(stats_game_diff, by = join_by(match.matchId == providerId)) |> 
  left_join(team_rp, by = join_by(match.matchId == providerId, 
                                  match.homeTeamId == teamId)) |> 
  rename(rating_selected_home = ratingPoints_selected) |> 
  left_join(team_rp, by = join_by(match.matchId == providerId, 
                                  match.awayTeamId == teamId)) |> 
  rename(rating_selected_away = ratingPoints_selected) |> 
  drop_na() |> 
  select(match.matchId, 
         round.year, 
         margin, 
         home_elo:rating_selected_away)


# Modelling -----------

set.seed(42)

cores <- parallel::detectCores()

# Split by just 2023
n_2023 <- sum(final_dat$round.year == 2023)
n_all <- nrow(final_dat)
prop <- 1 - (n_2023/n_all)

# Create training sets
train_test_split <- initial_time_split(final_dat, prop = prop)

dat_train <- training(train_test_split)
dat_test <- testing(train_test_split)


folds <- rsample::vfold_cv(dat_train, v = 5)

# Create Model
xgb_mod <- boost_tree(
  trees = 1000,
  tree_depth = tune(), min_n = tune(),
  loss_reduction = tune(),                     ## first three: model complexity
  sample_size = tune(), mtry = tune(),         ## randomness
  learn_rate = tune()                          ## step size
) |>
  set_engine("xgboost", num.threads = cores, eval_metric = "mae") |>
  set_mode("regression")


rec_obj <- recipe(margin ~ ., data = dat_train) |>
  update_role(match.matchId, new_role = "id variable") |>
  update_role(round.year, new_role = "id variable") |>
  update_role_requirements("id variable", bake = FALSE)

# Create Workflow
xgb_wflow <- workflow() %>%
  add_model(xgb_mod) %>%
  add_recipe(rec_obj)

# Create Tuning Grid
xgb_grid <- grid_latin_hypercube(
  tree_depth(),
  min_n(),
  loss_reduction(),
  sample_size = sample_prop(),
  finalize(mtry(), dat_train),
  learn_rate(),
  size = 30
)

# Train and tune model
doParallel::registerDoParallel()

xgb_res <- xgb_wflow |>
  tune_grid(resamples = folds,
            grid = xgb_grid,
            control = control_grid(save_pred = TRUE),
            metrics = metric_set(mae)
  )

# Select best model based on ROC_AUC score
best_mae <- select_best(xgb_res, "mae")

final_xgb <- finalize_workflow(
  xgb_wflow,
  best_mae
)

last_xbg_fit <-
  final_xgb %>%
  last_fit(train_test_split)

last_xbg_fit |>
  collect_metrics()

last_xgb_mae2 <-
  last_xbg_fit %>%
  collect_predictions() |> 
  mae( margin, .pred)

vis <- last_xbg_fit %>%
  extract_fit_parsnip()

vis |> vip(num_features = 20,
           mapping = aes(fill = .data[["Variable"]], colour = .data[["Variable"]]),
           aesthetics = list()) +
  labs(title = "Variable Importance",
       subtitle = "Importance of each variable to the final XGB model") +
  theme_minimal() +
  theme(axis.text.y = element_text(size = rel(1.5))) +
  guides(fill = FALSE,
         colour = FALSE)


# Now do final fit

xgb_fit <- fit(final_xgb, data = dat_train)

predict <- dat_test |> 
  select(match.matchId, round.year, margin) |> 
  bind_cols(predict(xgb_fit, dat_test, type = "conf_int")) 

predict

# New model --------------------------
predict_test <- dat_test |> 
  select(match.matchId, round.year, margin) |>
  mutate(win = as.factor(ifelse(margin > 0, TRUE, FALSE))) |> 
  bind_cols(predict(xgb_fit, dat_test)) |> 
  rename(marg_predict = .pred) |> 
  select(win, marg_predict)



predict_train <- dat_train |> 
  select(match.matchId, round.year, margin) |>
  mutate(win = as.factor(ifelse(margin > 0, TRUE, FALSE))) |> 
  bind_cols(predict(xgb_fit, dat_train)) |> 
  rename(marg_predict = .pred) |> 
  select(win, marg_predict)


lr_mod <- 
  logistic_reg() %>% 
  set_engine("glm")

lr_rec <- recipe(win ~ marg_predict, data = predict_train)

lr_workflow <- workflow() |> 
  add_model(lr_mod) |> 
  add_recipe(lr_rec)

model_fit <- lr_workflow |> 
  fit(data = predict_train)


tidy(model_fit, exponentiate = TRUE, conf.int = TRUE)

test_dat <- model_fit |> 
  augment(new_data = predict_test) |> 
  mutate(bits = ifelse(win == TRUE, 
                       1 + log2(.pred_TRUE), 
                       1 + log2(1 - .pred_TRUE)))

sum(test_dat$bits)
test_dat |> 
  ggplot2::ggplot(aes(x = marg_predict, y = .pred_TRUE)) +
  geom_point()
# Select variables
# home_elo
# away_elo
# percetnage_l5_diff
# shotsAtGoal_diff
# inside50s_diff
# ratingPoints_diff
# scoreLaunches_diff
# home_exp
# away_exp
# ratingPoints_selected