# Finals Sims

# Get top 8
sim_ladder <- sim_data_all %>%
  filter(Top.8) %>%
  arrange(Sim, Rank) %>%
  group_by(Sim) %>%
  select(Sim, Team, Rank) %>%
  group_split()

# Fixture - week 1
finals <- tibble(
  Season = last(game_dat$Season),
  Finals_week = 1,
  Game = (last(game_dat$Game)+1):(last(game_dat$Game)+4),
  Round = (last(game_dat$Round) + 1),
  Home.Team = sim_ladder[[1]]$Team[c(1,2,4,5)],
  Away.Team = sim_ladder[[1]]$Team[c(4,3,8,6)],
  Venue = ""
)


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



sim_data <- sim_elo_perterbed %>%
  map(~elo.prob(form, data = remaining_fixture, elos = .x)) %>%
  map2_df(sims, ~mutate(
    remaining_fixture, Probability = .x,
    Margin = ceiling(map_outcome_to_margin(Probability, B = B)),
    Sim = .y)) %>%
  bind_rows(res)


# Create week 2 fixture

# Create week 3 fixture

# Create week 4 fixture



map(perturb_elos) %>%
  map(~elo.prob(form, data = remaining_fixture, elos = .x)) %>%
  map2_df(sims, ~mutate(
    remaining_fixture, Probability = .x,
    Margin = ceiling(map_outcome_to_margin(Probability, B = B)),
    Sim = .y)) %>%
  bind_rows(res)