library(tidyverse)
library(elo)
library(fitzRoy)
library(lubridate)

# Get data
results <- fitzRoy::get_match_results()
results <- results %>%
  mutate(seas_rnd = paste0(Season, ".", Round.Number),
         First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
         )

fixture <- fitzRoy::get_fixture()
fixture <- fixture %>%
  filter(Date > max(results$Date)) %>%
  mutate(Date = ymd(format(Date, "%Y-%m-%d"))) %>%
  rename(Round.Number = Round)

# Simple ELO
# Set parameters
HGA <- 30
carryOver <- 0.5
B <- 0.03
k_val <- 20

# Create margin function to ensure result is between 0 and 1
map_margin_to_outcome <- function(margin, B) {
  1 / (1 + (exp(-B * margin)))
}

# Run ELO
elo.data <- elo.run(
  map_margin_to_outcome(Home.Points - Away.Points, B = B) ~
  adjust(Home.Team, HGA) +
    Away.Team +
    group(seas_rnd) +
    regress(First.Game, 1500, carryOver),
  k = k_val,
  data = results
)

as.data.frame(elo.data)
as.matrix(elo.data)
final.elos(elo.data)

# Do predictions
fixture <- fixture %>%
  mutate(Prob = predict(elo.data, newdata = fixture))

head(fixture)
