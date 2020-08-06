# Get and Clean Data
# This is step 1 in a weekly data process.

# Get Data ----------------------------------------------------------------
# 
# Get fixture from afl and turn it into afltables format
# Get results from afltables
# Get results from footywire and merge into results

# Get fixture data using FitzRoy
_get_fixture <- function(filt_date){
  fixture <- fitzRoy::get_fixture() %>%
    filter(Date >= filt_date)
  
  fixture <- fixture %>%
    mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
    rename(Round.Number = Round)
  
}



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


# Get states data - this comes from another script I run when a new venue or team occurs
states <- read_rds(here::here("data_files", "raw-data", "states.rds"))
message("Data loaded")

# Data Cleaning -----------------------------------------------------------
# Fix Venues
venue_fix <- function(x){
  case_when(
    x == "MCG" ~ "M.C.G.",
    x == "SCG" ~ "S.C.G.",
    x == "Etihad Stadium" ~ "Docklands",
    x == "Marvel Stadium" ~ "Docklands",
    x == "Blundstone Arena" ~ "Bellerive Oval",
    x == "GMHBA Stadium" ~ "Kardinia Park",
    x == "Spotless Stadium" ~ "Blacktown",
    x == "Showground Stadium" ~ "Blacktown",
    x == "UTAS Stadium" ~ "York Park",
    x == "Mars Stadium" ~ "Eureka Stadium",
    x == "Adelaide Arena at Jiangwan Stadium" ~ "Jiangwan Stadium",
    x == "TIO Traegar Park" ~ "Traeger Park",
    x == "Metricon Stadium" ~ "Carrara",
    x == "TIO Stadium" ~ "Marrara Oval",
    x == "Optus Stadium" ~ "Perth Stadium",
    x == "Canberra Oval" ~ "Manuka Oval",
    x == "UNSW Canberra Oval" ~ "Manuka Oval",
    TRUE ~ as.character(x)
  )
}

# Bind together and fix stadiums
game_dat <- bind_rows(results, fixture) %>%
  mutate(Game = row_number()) %>%
  ungroup() %>%
  mutate(Venue = venue_fix(Venue)) %>%
  mutate(Round = Round.Number)