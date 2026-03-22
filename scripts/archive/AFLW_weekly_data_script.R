# Womens script

# Setup
#devtools::install_github("jimmyday12/fitzRoy", force = TRUE)
library(fitzRoy)
library(tidyverse)
library(elo)

seas <- 2021

# Get data ---------------------------------------------------------------------
# Results
results <- fetch_results_afl(2012:seas, comp = "AFLW")

results <- results %>%
  rename(home_team = match.homeTeam.name,
         away_team = match.awayTeam.name,
         home_score = homeTeamScore.matchScore.totalScore,
         away_score = awayTeamScore.matchScore.totalScore)

# Fixture
fixture <- fetch_fixture_afl(seas, comp = "AFLW")

fixture <- fixture %>%
  filter(status != "CONCLUDED") %>%
  rename(home_team = home.team.name,
         away_team = away.team.name,
         home_score = home.score.totalScore,
         away_score = away.score.totalScore
         )
# Ladder
ladder <- fetch_ladder_afl(seas, comp = "AFLW")

stats <- 2017:2020 %>%
  purrr::map_dfr(fetch_player_stats_afl, comp = "AFLW", .id = "season")

# Do ELOS ----------------------------------------------------------------------
results <- results %>%
  mutate(first_round = ifelse(round.roundNumber == 1, TRUE, FALSE))

fixture <- fixture %>%
  mutate(first_round = ifelse(round.roundNumber == 1, TRUE, FALSE))

elo_dat <- elo.run(score(home_score, away_score) ~ 
                     adjust(home_team, 10) + 
                     away_team +
                     k(20*log(abs(home_score - away_score) + 1)) +
                     regress(first_round, 1500, 0.2), 
                   group = round.roundId,
                   data = results)

# Colley
colley_dat <- elo.colley(score(home_score, away_score) ~ 
                  adjust(home_team, 10) + 
                  away_team + 
                    group(round.roundId),
                data = results, 
           subset = home_score != away_score,
           running = TRUE, skip = 5)

# Markov
markov_dat <- elo.markovchain(score(home_score, away_score) ~ 
                           adjust(home_team, 10) + 
                           away_team +
                             group(round.roundId),
                         data = results, 
                         k = 0.7,
                         subset = home_score != away_score,
                         running = TRUE, skip = 2)

# GLM
glm_dat <- elo.glm(score(home_score, away_score) ~ 
                                adjust(home_team, 10) + 
                                away_team +
                   group(round.roundId),
                   data = results, 
                   subset = home_score != away_score,
                   running = TRUE, skip = 6)

# winpct
winpct_dat <- elo.winpct(score(home_score, away_score) ~ 
                     adjust(home_team, 10) + 
                     away_team +
                     group(round.roundId),
                   data = results, 
                   subset = home_score != away_score,
                   running = TRUE, skip = 2)

summary(glm_dat)
summary(markov_dat)
summary(colley_dat)
summary(elo_dat)
summary(winpct_dat)

# MOV --------
# GLM
glm_mov_dat <- elo.glm(mov(home_score, away_score) ~ 
                     adjust(home_team, 10) + 
                     away_team,
                   data = results, 
                   subset = home_score != away_score,
                   #unning = TRUE, skip = 6,
                   family = "gaussian")

colley_mov_dat <- elo.colley(mov(home_score, away_score) ~ 
                         adjust(home_team, 10) + 
                         away_team,
                       data = results, 
                       subset = home_score != away_score,
                       running = TRUE, skip = 2,
                       family = "gaussian")

summary(glm_mov_dat)
summary(colley_mov_dat)

fixture_simple <- fixture %>%
  rename(round.roundId = round.id) %>%
  select(compSeason.year, round.roundNumber, round.roundId, home_team, away_team)

# Predictions ------------------------------------------------------------------
fixture_simple_prob <- fixture_simple %>%
  mutate(elo.prob = predict(elo_dat, newdata = fixture_simple),
         glm.prob = predict(glm_dat, newdata = fixture_simple),
         markov.prob = predict(markov_dat, newdata = fixture_simple),
         colley.prob = predict(colley_dat, newdata = fixture_simple),
         winpct.prob = predict(winpct_dat, newdata = fixture_simple))

View(fixture_simple_prob)

fixture_simple_mov <- fixture_simple %>%
  mutate(elo.prob = predict(elo_dat, newdata = fixture_simple),
         glm.mov = predict(glm_mov_dat, newdata = fixture_simple),
         #markov.prob = predict(markov_dat, newdata = fixture_simple),
         #winpct.prob = predict(winpct_dat, newdata = fixture_simple),
         colley.mov = predict(colley_mov_dat, newdata = fixture_simple))
View(fixture_simple_mov)
# Simulate Season --------------------------------------------------------------

# Simulate Finals --------------------------------------------------------------

# Save data