library(pacman)
p_load(betfaiR, tidyverse)


bf <- betfair(usr = Sys.getenv("bf_id"),
              pwd = Sys.getenv("bf_pw"),
              key = Sys.getenv("bf_api"))

# Get compeittions
bf$competitions() %>%
  filter(str_detect(competition_name, "World Cup"))

world_cup_id <- 5614746

# Now get all events from world cup
events <- bf$events(filter = marketFilter(competitionIds = world_cup_id, 
                                marketTypeCodes = "MATCH_ODDS")) %>%
  filter(str_detect(event_name, "v"))

# Get the games
games <- events$event_id %>%
  map(~ bf$marketCatalogue(filter = marketFilter(eventIds = .x, 
                                              marketTypeCodes = "MATCH_ODDS"))) %>%
  map(~ bf$marketBook(marketIds = .x[[1]]$market$marketId)) %>%
  map2_dfr(.y = events$event_name,
        ~ .x[[1]]$basic %>% 
        mutate(id = c("team_1_betfair_odds", "team_2_betfair_odds", "draw_betfair_odds"),
               game = .y) %>%
         select(id, lastPriceTraded, game) %>%
         spread(id, lastPriceTraded) 
       ) %>%
  mutate(date = events$event_openDate)

# Split out games
games <- games %>%
  mutate(date = as_date(ymd_hms(date))) %>%
  separate(game, into = c("team_1", "team_2"), sep = "v") %>%
  arrange(date)

# Write out
write_csv(games, here::here("projects", "world-cup-2018", "world_cup_2018_betfair.csv"))




