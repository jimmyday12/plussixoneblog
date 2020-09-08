convert_teams_afl <- function(team){
  case_when(
    team == "Western Bulldogs" ~ "Footscray",
    team == "Adelaide Crows" ~ "Adelaide",
    team == "GWS Giants" ~ "GWS",
    team == "Gold Coast Suns" ~ "Gold Coast",
    team == "West Coast Eagles" ~ "West Coast",
    team == "Sydney Swans" ~ "Sydney",
    team == "Geelong Cats" ~ "Geelong",
    TRUE ~ team)
}


convert_results <- function(df) {
  df <- df %>%
  mutate(Season = Date[1] %>% format("%Y") %>% as.numeric(),
         Home.Team = ifelse(Home.Team == "Western Bulldogs", "Footscray", Home.Team),
         Home.Team = ifelse(Home.Team == "Brisbane", "Brisbane Lions", Home.Team),
         Away.Team = ifelse(Away.Team == "Western Bulldogs", "Footscray", Away.Team),
         Away.Team = ifelse(Away.Team == "Brisbane", "Brisbane Lions", Away.Team),
         Margin = Home.Points - Away.Points,
         Round.Number = stringr::str_extract(Round, "[0-9]+") %>% as.numeric(),
         First.Game = Round.Number == 1,
         Round.Type = ifelse(stringr::str_detect(Round, "Round"), "Regular", "Finals"),
         seas_rnd = paste0(Season, ".", Round.Number)) %>%
  select(-Time)
}


get_data <- function(season, filt_date, grand_final_bug = FALSE, fixture_bug = FALSE) {
  
# Get fixture data using FitzRoy
fixture <- fitzRoy::get_fixture() %>%
  filter(Date >= filt_date)

# get afl fixture
fixture_afl <- fitzRoy::get_afl_fixture(season)

fixture_afl <- fixture_afl %>%
  mutate(Game = NA,
         Date = date,
         Round = round_roundNumber,
         Home.Team = home_name,
         Away.Team = away_name,
         Venue = venue_name,
         Season = season
         ) %>%
  select(Game, Date, Round, Home.Team, Away.Team, Venue, Season)

fixture_afl <- fixture_afl %>%
  mutate(Home.Team = convert_teams_afl(Home.Team),
         Away.Team = convert_teams_afl(Away.Team))

fixture <- fixture_afl %>%
  mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
  rename(Round.Number = Round)

if (grand_final_bug){
  # temp
  fixture <- tibble(
    Date = ymd("2018/09/29"),
    Season = 2018,
    Season.Game = 1,
    Round = "28",
    Round.Number = 28,
    Home.Team = "West Coast",
    Away.Team = "Collingwood",
    Venue = "MCG"
  )
}

if(fixture_bug) fixture$Round.Number = fixture$Round.Number - 1

# Get results
results <- fitzRoy::get_match_results() %>%
  mutate(
    seas_rnd = paste0(Season, ".", Round.Number),
    First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
  )

# Check for new results
results_new <- get_footywire_match_results(season, last_n_matches = 10)


results_new <- convert_results(results_new)

results <- bind_rows(results, results_new) %>%
  group_by(Date, Home.Team, Away.Team) %>% 
  filter(!(row_number() == 2 & is.na(Game))) %>%
  ungroup()

# Get states data - this comes from another script I run when a new venue or team occurs
states <- read_rds(here::here("data_files", "raw-data", "states.rds"))
message("Data loaded")
dat <- list(fixture = fixture,
            results = results,
            states = states)
}
