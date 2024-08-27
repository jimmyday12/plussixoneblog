# Check results
check_results <- function(season) {
  new_results <- fetch_results_footywire(season, 
                                         round_number = NULL, 
                                         last_n_matches = 9) 
  
  if(is.null(new_results)) {
    return(FALSE)
  }
  
  old_results <- read_rds(here::here("data_files", "raw-data", "AFLM.rds"))
  
  new <- new_results %>% 
    convert_results() %>%
    select(Home.Team, Away.Team, Round, Date, Venue) %>%
    filter(Round == last(Round)) %>%
    mutate(Venue = trimws(Venue),
           Venue = venue_fix(Venue)) %>%
    select(-Round)
  
  n_results <- nrow(new)
  
  old <- old_results$results %>%
    slice(tail(row_number(), n_results)) %>%
    filter(Round == last(Round)) %>%
    select(Home.Team, Away.Team, Date, Venue) 
  
  return(!isTRUE(dplyr::all.equal(new, old)))

  
}

check_fixture <- function(season, new_season = FALSE) {
  old_dat <- read_rds(here::here("data_files", "raw-data", "AFLM.rds"))
  
  if(is_null(old_dat$predictions)) return(FALSE)
  
  old <-  old_dat$predictions %>%
    slice(head(row_number(), 9)) %>%
    filter(Round.Number == first(Round.Number)) %>%
    select(Home.Team, Away.Team, Date, Venue, Round.Number) 
  
  if (new_season) {
    new_fixtures <- fitzRoy::fetch_fixture_afl(season, round_number = 1)
  } else {
    new_fixtures <- fitzRoy::fetch_fixture_afl(season, round_number = old$Round.Number[1])
  }
  
  
  new <- new_fixtures %>%
    mutate(Date = lubridate::ymd_hms(new_fixtures$utcStartTime) %>% as.Date(),
           Round.Number = round.roundNumber,
           Home.Team = convert_teams_afl(home.team.name),
           Away.Team = convert_teams_afl(away.team.name),
           Venue = venue_fix(venue.name)) %>%
    select(Home.Team, Away.Team, Date, Venue, Round.Number)
  
  return(!isTRUE(dplyr::all.equal(new, old)))
  
}
