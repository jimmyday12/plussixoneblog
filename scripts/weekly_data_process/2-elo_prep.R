

## Add interstate
get_state <- function(team, venue, all_teams, all_venues){
  all_teams$State[match(team, all_teams$Team)] != all_venues$State[match(venue, all_venues$Venue)]
}

elo_prep_calculations <- function(game_dat, states, last_n_games) {
  # We want to calculate the experience and interstate value for each team
  
  
  # Experience - number of games in last 100
  # Create rolling function
  #last_n_games = 100
  count_games <- rollify(function(x) sum(last(x) == x), window = last_n_games, na_value = NA)
  
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
  
  game_dat <- game_dat %>%
    mutate(Home.Interstate = get_state(Home.Team, Venue, all_teams = states$team, all_venues = states$venue),
           Away.Interstate = get_state(Away.Team, Venue, all_teams = states$team, all_venues = states$venue),
           Home.Factor = 1,
           Away.Factor = 0)
  
  return(game_dat)
}


