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
    team == "Narrm" ~ "Melbourne",
    team == "Walyalup" ~ "Fremantle",
    team == "Yartapuulti" ~ "Port Adelaide",
    team == "Euro-Yroke" ~ "St Kilda",
    team == "Kuwarna" ~ "Adelaide",
    team == "Waalitj Marawar" ~ "West Coast",
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

# Round types come from the round name: everything AFL.com.au calls a "Round" is
# home and away, the rest are finals. The Wildcard Round (new in 2026) is a
# finals round that happens to be named like a home and away one, so call it out
# explicitly - getting it wrong puts it on the ladder and shifts every finals
# week by one.
is_finals_round <- function(round_name) {
  finals <- !stringr::str_detect(round_name, "Round") |
    stringr::str_detect(tolower(round_name), "wild ?card")
  
  ifelse(is.na(finals), FALSE, finals)
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
           Round.Type = ifelse(is_finals_round(round.name), "Finals", "Regular"),
           Margin = Home.Points - Away.Points) %>%
    select(Game, Date, Season, Date, Round, Round.Number, Round.Type,Venue,
           Home.Team, Home.Goals, Home.Behinds, Home.Points,
           Away.Team, Away.Goals, Away.Behinds, Away.Points,
           Margin)
  
  df %>%
    mutate(Home.Team = convert_teams_afl(Home.Team),
           Away.Team = convert_teams_afl(Away.Team))
  
}


# AFL Tables labels rounds with its own codes (R1, R2, ..., QF, SF, PF, GF) and
# fitzRoy maps those onto round numbers using a fixed set of levels. Any round
# it doesn't know about - the Wildcard Round, new in 2026 - comes back with
# Round.Number = NA and Round.Type = "Regular", which then poisons everything
# keyed off round numbers (the ladder lookup below, finals weeks, sims).
# AFL.com.au numbers every round it plays, so use it as the source of truth for
# any game that appears in both sets of results.
patch_round_data_afl <- function(results, results_afl) {
  if (is.null(results_afl) || nrow(results_afl) == 0) return(results)

  round_lookup <- results_afl %>%
    transmute(Date,
              Home.Team,
              Away.Team,
              Round.Number.afl = as.numeric(Round.Number),
              Round.Type.afl   = as.character(Round.Type)) %>%
    distinct(Date, Home.Team, Away.Team, .keep_all = TRUE)

  results %>%
    left_join(round_lookup, by = c("Date", "Home.Team", "Away.Team")) %>%
    mutate(Round.Number = coalesce(Round.Number.afl, as.numeric(Round.Number)),
           Round.Type   = coalesce(Round.Type.afl, as.character(Round.Type))) %>%
    select(-Round.Number.afl, -Round.Type.afl)
}

# The AFL only publishes a ladder for home and away rounds and fitzRoy returns
# NULL (with a warning) whenever it can't find one, which used to blow up the
# whole run. Walk back a few rounds before giving up so an unexpected round -
# a new round type, or a round the API hasn't caught up with - can't stop us.
fetch_ladder_safe <- function(season, round_number, comp = "AFLM", max_tries = 3) {
  if (length(round_number) != 1 || !is.finite(round_number)) return(NULL)

  rounds <- round_number - seq_len(max_tries) + 1
  rounds <- rounds[rounds >= 0]

  for (rnd in rounds) {
    ladder <- tryCatch(
      suppressWarnings(fitzRoy::fetch_ladder_afl(season,
                                                 round_number = rnd,
                                                 comp = comp)),
      error = function(e) NULL
    )

    if (!is.null(ladder) && nrow(ladder) > 0) return(ladder)

    cli::cli_alert_warning("No ladder found for round {rnd} of {season}")
  }

  NULL
}

get_data <- function(season, filt_date, grand_final_bug = FALSE, fixture_bug = FALSE, opening_round = FALSE) {
  
# Get fixture data using FitzRoy
#fixture <- fitzRoy::fetch_fixture_footywire(season) %>%
#  filter(Date >= filt_date)

cli::cli_progress_step("Fetching fixture")
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
         Finals = is_finals_round(round.name)
         ) %>%
  select(Game, Date, Round, round.name, Home.Team, Away.Team, Venue, Season, Finals, status)

fixture_afl <- fixture_afl %>%
  mutate(Home.Team = convert_teams_afl(Home.Team),
         Away.Team = convert_teams_afl(Away.Team))

fixture <- fixture_afl %>%
  mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
  rename(Round.Number = Round)

# Drop finals fixture rows where the AFL API hasn't determined the
# competing teams yet (placeholders like "10th", "Winner of QF1", etc).
# These aren't real teams, and finals matchups are simulated separately
# in 5-finals_sims.R, so these rows are just noise for the elo/experience
# calculations downstream.
placeholder_team_pattern <- "^[0-9]+(st|nd|rd|th)$|Winner of|Loser of|ranked"

# Keep the unfiltered fixture around - the placeholder rows are still the only
# record that games are left to play, which is how we tell a gap between finals
# weeks apart from the end of the season
fixture_all <- fixture

fixture <- fixture %>%
  filter(!str_detect(Home.Team, placeholder_team_pattern) &
         !str_detect(Away.Team, placeholder_team_pattern))

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
cli::cli_progress_step("Fetching AFL Tables Results")

seasons <- 1897:season
results <- fetch_results_afltables(seasons, NULL)

## Check which seasons have openeing round
cli::cli_progress_step("Checking for opening round")
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
cli::cli_progress_step("Getting AFL.com.au results")
results_new <- fetch_results(season, comp = "AFLM")

if (!is.null(results_new)) {
  cli::cli_progress_step("Merging Results")
  results_new <- convert_results_afl(results_new)
  
  # Take round number and round type from AFL.com.au wherever it has the game
  results <- patch_round_data_afl(results, results_new)
  
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
  mutate(Round.Number = ifelse(Round.Number < max(Round.Number, na.rm = TRUE) & is.na(Game),rnd + 1, Round.Number))

# Ladder 
cli::cli_progress_step("Getting Ladder")
df <- results %>% 
  filter(Season == season & Round.Type == "Regular" & !is.na(Margin))

if (nrow(df) == 0){
  ladder <- NULL
} else {
  # Last completed home and away round - finals rounds don't have a ladder
  round_number_afl <- suppressWarnings(max(df$Round.Number, na.rm = TRUE))
  ladder <- fetch_ladder_safe(season, round_number_afl, comp = "AFLM")
}

if (is.null(ladder)) {
  cli::cli_alert_warning("No ladder data available for {season}")
} else {
  ladder <- ladder %>%
    mutate(team.name = convert_teams_afl(team.name))
}


# Get states data - this comes from another script I run when a new venue or team occurs
cli::cli_progress_step("Getting venues data")
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

cli::cli_progress_done()

dat <- list(fixture = fixture,
            fixture_all = fixture_all,
            results = results,
            ladder = ladder,
            states = states)
}
