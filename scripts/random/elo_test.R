library(fitzRoy)
library(pacman)
pacman::p_load(tidyverse, elo, here, lubridate, tibbletime)

# Set Parameters
e <- 1.7
d <- -32
h <- 20
k_val <- 20
carryOver <- 0.05
B <- 0.04
sim_num <- 10000


# Get Train and Test
split_date <- lubridate::dmy("01/01/2019")
start_date <- lubridate::dmy("01/01/1990")


results <- fitzRoy::get_match_results()

results <- results %>%
  mutate(
    seas_rnd = paste0(Season, ".", Round.Number),
    First.Game = ifelse(Round.Number == 1, TRUE, FALSE)
  ) %>%
  select(Date, seas_rnd, Home.Team, Away.Team, Home.Points, Away.Points, First.Game)

train <- results %>%
  filter(Date < split_date & Date > start_date)

test <- results %>%
  filter(Date > split_date)


# Run Elo Models
glm_dat <- elo.glm(score(Home.Points, Away.Points) ~ 
                  Home.Team + 
                  Away.Team + 
                  group(seas_rnd) +
                  regress(First.Game, 1500, carryOver), 
                data = train,
                family = "binomial")

summary(glm_dat)
rank.teams(glm_dat)



elo_dat <- elo.run(
  score(Home.Points, Away.Points) ~
    adjust(Home.Team, 10) +
    adjust(Away.Team, -10) + 
    group(seas_rnd) +
    regress(First.Game, 1500, carryOver) +
    k(log(abs(Home.Points - Away.Points) + 1)),
  data = train
)

summary(elo_dat)
rank.teams(elo_dat)



train_predict <- train %>%
  mutate(elo_prob = round(predict(elo_dat, newdata = train), 3),
         marg = Home.Points - Away.Points)

train_predict



###### Model MOV
glm_dat <- stats::glm(formula = marg ~ elo_prob + 1, family = "gaussian", data = train_predict, 
           subset = NULL, na.action = stats::na.pass)

train_predict <- train_predict %>%
  mutate(marg_predict = predict(glm_dat, newdata = train_predict))
