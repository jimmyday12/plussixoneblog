simSeason <- function(fixture, team_elo = data.frame(), simulation = 1) {

  # initialise data frame
  simulated_results <- tibble()

  # Step through each game
  for (i in seq_along(fixture$Game)) {

    # get game details
    game <- fixture[i, ]

    # Find elo diff
    game$home_elo <- team_elo$ELO[(team_elo$Team == game$Home)]
    game$away_elo <- team_elo$ELO[(team_elo$Team == game$Away)]
    elo_diff <- game$home_elo - game$away_elo + HGA

    # Find expected outcome based on elo
    exp_margin <- find_expected_margin(elo_diff, M)

    # sample from rnorm of mean marg and historical SD
    game$margin <- round(rnorm(1, exp_margin, sd = 41))

    team_elo$ELO[(team_elo$Team == game$Home)] <- update_elo(game$margin, home_elo, away_elo)
    team_elo$ELO[(team_elo$Team == game$Away)] <- update_elo(game$margin, home_elo, away_elo, returns = "away")

    simulated_results <- simulated_results %>%
      bind_rows(game)
  }

  simulated_results <- simulated_results %>%
    mutate(sim_number = simulation)
  return(simulated_results)
}

library(tidyverse)

fixture <- dat.2017 %>%
  filter(RoundNum >= 5) %>%
  select(Game:Away)

current_elo <- x %>%
  group_by(Team) %>%
  filter(RoundNum < 5) %>%
  filter(TeamSeasGame == max(TeamSeasGame)) %>%
  select(Team, ELO_post) %>%
  rename(ELO = ELO_post)

library(purrr)
sims <- 1:500
pb <- progress_estimated(length(sims))
sims_df <- sims %>%
  map_df(~{
    pb$tick()$print() # update the progress bar (tick())
    simSeason(fixture, team_elo = current_elo, simulation = .x) # do function
  })




# Conmbine with existing

# Summarise wins
# Calculate Rank
# Calculate Percentage of finishing positions