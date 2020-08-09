# fix team names
fix_teams <- function(teams){
  teams %>%
    stringr::str_replace("W Bulldogs", "Footscray") %>%
    stringr::str_replace("Brisbane", "Brisbane Lions") %>%
    stringr::str_replace("North Melb", "North Melbourne") %>%
    stringr::str_replace("Port Adel", "Port Adelaide")
}

# Added once hubs announced
assign_interstate_hubs <- function(team, venue, current){
  stay_at_home_teams <- c("Gold Coast", "West Coast", "Fremantle", "Brisbane Lions")
  case_when(!is.na(venue) ~ current,
            team %in% stay_at_home_teams ~ FALSE,
            TRUE ~ TRUE)
}

assign_home_factor <- function(team, venue, current){
  stay_at_home_teams <- c("Gold Coast", "West Coast", "Fremantle", "Brisbane Lions")
  case_when(!is.na(venue) ~ current,
            team %in% stay_at_home_teams ~ 1,
            TRUE ~ 0)
}

fix_covid_season <- function(fixture){

  covid_fixture <- readr::read_csv(here::here("data_files", "raw-data", "afl_fixture_mock_2020.csv"))
  
  covid_fixture <- covid_fixture %>%
    rename(Home.Team = Home,
           Away.Team = Away) %>%
    mutate(Date = lubridate::dmy(Date)) %>%
    filter(Round > last(fixture$Round))
  
  covid_fixture <- covid_fixture %>%
    mutate_at(c("Home.Team", "Away.Team"), fix_teams)
  
  last_game_id <- last(fixture$Game)
  covid_fixture$Game <- (last_game_id + 1):(last_game_id + nrow(covid_fixture))
  
  fixture <- fixture %>%
    bind_rows(covid_fixture) %>%
    select(Game, Date, Round, Home.Team, Away.Team, Venue, Season, Round.Type, Round.Number, seas_rnd, First.Game, Season.Game, Home.Venue.Exp, Away.Venue.Exp, Home.Interstate, Away.Interstate, Home.Factor, Away.Factor) %>%
    mutate(Round.Number = Round,
           Home.Factor = ifelse(is.na(Home.Factor), 0, Home.Factor),
           Away.Factor = 0,
           Season = 2020,
           Home.Interstate = ifelse(is.na(Home.Interstate), TRUE, Home.Interstate),
           Away.Interstate = ifelse(is.na(Away.Interstate), TRUE, Away.Interstate),
           Home.Venue.Exp = ifelse(is.na(Home.Venue.Exp), 1, Home.Venue.Exp),
           Away.Venue.Exp = ifelse(is.na(Away.Venue.Exp), 1, Away.Venue.Exp)) 

fixture <- fixture %>%
  mutate(Home.Interstate = assign_interstate_hubs(Home.Team, Venue, Home.Interstate),
         Away.Interstate = assign_interstate_hubs(Away.Team, Venue, Away.Interstate),
         Home.Factor = assign_home_factor(Home.Team, Venue, Home.Factor))
}
