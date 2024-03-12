convert_teams_afl <- function(team){
  case_when(
    team == "Western Bulldogs" ~ "Footscray",
    team == "Adelaide Crows" ~ "Adelaide",
    team == "GWS Giants" ~ "GWS",
    team == "GWS GIANTS" ~ "GWS",
    team == "Gold Coast Suns" ~ "Gold Coast",
    team == "Gold Coast SUNS" ~ "Gold Coast",
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
         Home.Team = ifelse(Home.Team == "GWS GIANTS", "GWS", Home.Team),
         Home.Team = ifelse(Home.Team == "Gold Coast SUNS", "Gold Coast", Home.Team),
         Away.Team = ifelse(Away.Team == "Western Bulldogs", "Footscray", Away.Team),
         Away.Team = ifelse(Away.Team == "Brisbane", "Brisbane Lions", Away.Team),
         Away.Team = ifelse(Away.Team == "GWS GIANTS", "GWS", Away.Team),
         Away.Team = ifelse(Away.Team == "Gold Coast SUNS", "Gold Coast", Away.Team),
         Margin = Home.Points - Away.Points,
         Round.Type = ifelse(stringr::str_detect(Round, "Round"), "Regular", "Finals"),
         Round.Number = stringr::str_extract(Round, "[0-9]+") %>% as.numeric())
  
  df <- df %>%
    mutate(
      Round.Number = ifelse(Round.Type == "Finals", max(df$Round.Number, na.rm = TRUE) + 1, Round.Number),
      First.Game = Round.Number == 1,
      seas_rnd = paste0(Season, ".", Round.Number)) 
         
  df %>%
    select(-Time)
}

convert_results_afl <- function(df) {
  df <- df %>%
    rename(Round = round.abbreviation,
           Round.Number = round.roundNumber, 
           Home.Team = match.homeTeam.name,
           Home.Goals = homeTeamScore.matchScore.goals,
           Home.Behinds = homeTeamScore.matchScore.behinds,
           Home.Points = homeTeamScore.matchScore.totalScore,
           Away.Team = match.awayTeam.name,
           Away.Goals = awayTeamScore.matchScore.goals,
           Away.Behinds = awayTeamScore.matchScore.behinds,
           Away.Points = awayTeamScore.matchScore.totalScore,
           Venue = venue.name) %>%
    mutate(Game = as.numeric(NA),
           Season = as.numeric(round.year),
           Date = lubridate::as_date(match.date, tz = "GMT"),
           Round.Type = ifelse(stringr::str_detect(round.name, "Round"), "Regular", "Finals"),
           Margin = Home.Points - Away.Points) %>%
    select(Game, Date, Season, Date, Round, Round.Number, Round.Type,Venue,
           Home.Team, Home.Goals, Home.Behinds, Home.Points,
           Away.Team, Away.Goals, Away.Behinds, Away.Points,
           Margin)
  
  fix_names <- data.frame(
    old_name = c("Western Bulldogs", "Adelaide Crows", "GWS Giants", "GWS GIANTS", 
                 "Gold Coast Suns", "Gold Coast SUNS", 
                 "West Coast Eagles", "Geelong Cats", "Sydney Swans"),
    new_name = c("Footscray", "Adelaide", "GWS", "GWS", 
                 "Gold Coast", "Gold Coast", 
                 "West Coast", "Geelong", "Sydney")
  )
  
  df %>%
    left_join(fix_names, by = c("Home.Team" = "old_name")) %>%
    mutate(Home.Team = ifelse(is.na(new_name), Home.Team, new_name)) %>%
    select(-new_name) %>%
    left_join(fix_names, by = c("Away.Team" = "old_name")) %>%
    mutate(Away.Team = ifelse(is.na(new_name), Away.Team, new_name)) %>%
    select(-new_name)
  
}


get_data <- function(season, filt_date, grand_final_bug = FALSE, fixture_bug = FALSE, opening_round = FALSE) {
  
# Get fixture data using FitzRoy
#fixture <- fitzRoy::fetch_fixture_footywire(season) %>%
#  filter(Date >= filt_date)

# get afl fixture
fixture_afl <- fitzRoy::fetch_fixture_afl(season)

fixture_afl <- fixture_afl %>%
  mutate(Game = NA,
         Date = lubridate::ymd_hms(fixture_afl$utcStartTime) %>% as.Date(),
         Time = lubridate::ymd_hms(fixture_afl$utcStartTime) %>% as_datetime(),
         Round = round.roundNumber,
         Home.Team = home.team.name,
         Away.Team = away.team.name,
         Venue = venue.name,
         Season = lubridate::ymd_hms(fixture_afl$utcStartTime) %>% format("%Y") %>% as.numeric(),
         Finals = ifelse(str_detect(round.name, "Round"), FALSE, TRUE) 
         ) %>%
  select(Game, Date, Round, round.name, Home.Team, Away.Team, Venue, Season, Finals, status)

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

seasons <- 1897:season

results <- fetch_results_afltables(seasons, NULL)

## Check which seasons have openeing round
seasons_afl <- 2015:season

ind_opening_round <- seasons_afl |> 
  purrr::map(fetch_fixture_afl, 0) |> 
  purrr::map_lgl(~nrow(.x) > 0) 

seasons_opening_round <- seasons_afl[ind_opening_round]

results <- results |> 
    mutate(Round.Number = ifelse(Season %in% seasons_opening_round, 
                                 Round.Number - 1, 
                                 Round.Number))

# Check for new results
#results_new <- fetch_results_footywire(season, last_n_matches = 10)
#results_new <- convert_results(results_new)
results_new <- fetch_results(season, comp = "AFLM")

if (!is.null(results_new)) {
  results_new <- convert_results_afl(results_new)
  
  results <- bind_rows(results, results_new) %>%
    group_by(Date, Home.Team, Away.Team) %>% 
    filter(!(row_number() == 2 & is.na(Game))) %>%
    ungroup() %>%
    mutate(Game = ifelse(is.na(Game), row_number(), Game))
}


results <- results %>%
    mutate(
      seas_rnd = paste0(Season, ".", Round.Number),
      First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
    )
  
season_rounds <- results$Round.Number[results$Season == season]


if (length(season_rounds) == 0){
  rnd <- 1
} else {
  rnd <- max(results$Round.Number[results$Season == season], na.rm = TRUE)
}


results <- results %>%
  mutate(Round.Number = ifelse(Round.Number < max(Round.Number) & is.na(Game),rnd + 1, Round.Number))

# Ladder 
df <- results %>% 
  filter(Season == season & Round.Type == "Regular" & !is.na(Margin))

if (nrow(df) == 0){
  ladder <- NULL
} else {
  round_number_afl <- max(df$Round.Number)
  ladder <- fitzRoy::fetch_ladder_afl(season, round_number = round_number_afl, comp = "AFLM")
  
  ladder <- ladder %>%
    mutate(team.name = convert_teams_afl(team.name))
}


# Get states data - this comes from another script I run when a new venue or team occurs
states <- read_rds(here::here("data_files", "raw-data", "states.rds"))

states$venue <- states$venue %>%
  mutate(Ground = ifelse(Venue == "M.C.G.", "MCG", Ground),
         Ground = ifelse(Venue == "S.C.G.", "SCG", Ground),
         Ground = ifelse(Venue == "Gabba.", "Gabba", Ground),
         State = ifelse(Venue == "Gabba", "Queensland", State),
         Ground = ifelse(Venue == "Wellington", "Wellington Regional Stadium", Ground),
         Ground = ifelse(Venue == "Olympic Park", "Olympic Park", Ground),
         State = ifelse(Venue == "Manuka Oval", "Australian Capital Territory", State),
         Ground = ifelse(Venue == "Perth Stadium", "Perth Stadium", Ground),
         Ground = ifelse(Venue == "Canberra Oval", "Canberra Oval", Ground),
         Ground = ifelse(Venue == "Manuka Oval", "Manuka Oval", Ground),
         Ground = ifelse(Venue == "Riverway Stadium", "Riverway Stadium", Ground))

states$venue <- states$venue %>%
  select(-starts_with("dist")) %>%
  distinct()

write_rds(states, here::here("data_files", "raw-data", "states.rds"))

message("Data loaded")
dat <- list(fixture = fixture,
            results = results,
            ladder = ladder,
            states = states)
}
