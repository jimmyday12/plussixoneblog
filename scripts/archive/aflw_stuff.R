#devtools::install_github("jimmyday12/fitzRoy")
library(fitzRoy)
library(tidyverse)
library(elo)

# get data
results <- 2017:2022 %>%
  purrr::map_dfr(fetch_results_afl, comp = "AFLW")

results_clean <- results %>%
  rename(homeTeamScore = homeTeamScore.matchScore.totalScore,
         awayTeamScore = awayTeamScore.matchScore.totalScore,
         homeTeamId = match.homeTeam.teamId,
         awayTeamId = match.awayTeam.teamId,
         year = round.year,
         roundId = round.roundId) 

team_ids <- fixture %>% 
  select(home.team.providerId, home.team.name) %>% 
  rename(teamName = home.team.name,
         teamId = home.team.providerId) %>%
  distinct()

new_teams <- data.frame(homeTeamId = c("CD_T9407", "CD_T9409"),
                        awayTeamId = c("CD_T9406", "CD_T9408"),
                        homeTeamScore = c(0, 1),
                        awayTeamScore = c(0, 1),
                        year = c("2022", "2022"),
                        roundId = c("CD_R202226415", "CD_R202226415"))

results_new <- bind_rows(results_clean , new_teams)

elo_dat <- elo::elo.run(score(homeTeamScore, 
                              awayTeamScore) ~
                          adjust(homeTeamId, 5) +
                          awayTeamId +
                          regress(year, 1500, 0.2) +
                          group(roundId),
                        k = 20,
                        initial.elos = 1500,
                        data = results_new)

final.elos(elo_dat)

fixture <- fetch_fixture_afl(2022, comp = "AFLW")

fixture_clean <- fixture %>%
  filter(status != "CONCLUDED" & status != "CANCELLED") %>%
  rename(homeTeamId = home.team.providerId,
         awayTeamId = away.team.providerId,
         year = compSeason.year,
         roundId = round.id)



fixture_clean$prob <- predict(elo_dat, newdata = fixture_clean)

predictions <- fixture_clean %>%
  select(id, utcStartTime, compSeason.name, status, year, round.name, 
         venue.name,
         home.team.club.name, away.team.club.name, prob) 

?lm
