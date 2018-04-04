# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(tidyverse, rvest, fuzzyjoin, here)

# Get data ----------------------------------------------------------------
# Step 1: Get grounds and city from Wikipedia
wiki <- "https://en.wikipedia.org/wiki/List_of_Australian_Football_League_grounds"

wiki_html <- read_html(wiki)
grounds <- wiki_html %>%
  html_nodes("table") %>%
  html_table(fill = T) %>%
  .[1:3] %>%
  map_dfr(select, Ground:Capacity) %>%
  select_all(~make.names(.)) %>%
  mutate(
    State = ifelse(is.na(State), State.territory, State),
    in.world.cities = City %in% maps::world.cities$name
  ) %>%
  select(Ground, State)

# Step 2: Get tables from afltables
afl_url <- "https://afltables.com/afl/venues/overall.html"

venues <- read_html(afl_url) %>%
  html_nodes("table") %>%
  html_table(fill = F) %>%
  .[1] %>%
  as.data.frame() %>%
  select(Venue)

# Step 3: Match the two tables to get 'State'
# I use Fuzzy matching - I played around with the numbers of max_dist to give me the best matches
venues <- stringdist_left_join(
  venues, grounds, by = c("Venue" = "Ground"),
  method = "jw", distance_col = "dist",
  max_dist = 0.4
) %>%
  group_by(Venue) %>%
  filter(dist == min(dist) | is.na(dist))

# Still don't get Wellington, MCG and SCG - let's just add those manually
venue_states <- venues %>%
  mutate(State = case_when(
    Venue == "M.C.G." ~ "Victoria",
    Venue == "S.C.G." ~ "New South Wales",
    Venue == "Wellington" ~ "New Zealand",
    TRUE ~ as.character(State)
  ))

# Step 3: Give team states
team_states <- data.frame(
  Teams = c(
    "Fitzroy", "Collingwood", "Geelong", "Footscray",
    "Essendon", "St Kilda", "Melbourne", "Carlton",
    "Richmond", "University", "Hawthorn", "North Melbourne",
    "Fremantle", "West Coast",
    "Brisbane Lions", "Gold Coast",
    "Adelaide", "Port Adelaide",
    "Sydney", "GWS"
  ),
  State = c(rep("Victoria", 12), 
            rep("Western Australia", 2),
            rep("Queensland", 2),
            rep("South Australia", 2),
            rep("New South Wales", 2))
  )


# Save Data ---------------------------------------------------------------
states <- list(team = team_states, venue = venue_states)
write_rds(states, path = here("data", "raw-data", "states.rds"))