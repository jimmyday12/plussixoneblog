# ELO
# First some helper functions. These are used to adjust margin/outcome/k/HGA
# Squash margin between 0 and 1
map_margin_to_outcome <- function(margin, B) {
  1 / (1 + (exp(-B * margin)))
}

# Inverse of above, convert outcome to margin
map_outcome_to_margin <- function(outcome, B) {
  #log((1 / outcome) - 1) / - B
  (-log((1 - outcome)/outcome))/B
}

# Function to calculate k (how much weight we add to each result)
calculate_k <- function(margin, k_val, round) {
  mult <- (log(abs(margin) + 1) - log(round))
  x <- k_val * ifelse(mult <= 0, 1, mult)
  ifelse(x < k_val, k_val, x)
}

# Not using: function to calculate HGA adjust
calculate_hga <- function(experience, interstate, home.team, e, d, h){
  (e * log(experience)) +  (d * as.numeric(interstate)) + (h * home.team)
}

run_elo <- function(results, carryOver, B, e, d, h) {
  
  # Run ELO
  elo.data <- elo.run(
    map_margin_to_outcome(Home.Points - Away.Points, B = B) ~
      adjust(Home.Team, 
             calculate_hga(Home.Venue.Exp, Home.Interstate, Home.Factor, e = e, d = d, h = h)) +
      adjust(Away.Team, 
             calculate_hga(Away.Venue.Exp, Away.Interstate, Away.Factor, e = e, d = d, h = h)) +
      group(seas_rnd) +
      regress(Season, 1500, carryOver) +
      k(calculate_k(Home.Points - Away.Points, k_val, Round.Number)),
    data = results
  )
  
  # Need to combine this with results to get into long format. May be able to simplify.
  elo <- results %>%
    bind_cols(as.data.frame(elo.data)) %>%
    rename(
      Home.ELO = elo.A,
      Away.ELO = elo.B
    ) %>%
    mutate(
      Home.ELO_pre = Home.ELO - update.A,
      Away.ELO_pre = Away.ELO - update.B
    ) %>%
    select(Date, Game, Round, Round.Number, Home.Team, Away.Team, Home.ELO:Away.ELO_pre) %>%
    gather(variable, value, Home.Team:Away.ELO_pre) %>%
    separate(variable, into = c("Status", "variable"), sep = "\\.") %>%
    spread(variable, value) %>%
    mutate(ELO = as.numeric(ELO), ELO_pre = as.numeric(ELO_pre)) %>%
    group_by(Team) %>%
    arrange(Game) 
  
  # Also add predicted margin and probability to results
  results <- results %>%
    mutate(Probability = round(predict(elo.data, newdata = results), 3),
           Prediction = ceiling(map_outcome_to_margin(Probability, B = B)))
  

  
  list(elo.data = elo.data,
       elo = elo,
       results = results)
  
  
}


do_elo_predictions <- function(fixture, elo.data, carryOver, new_season = FALSE){
  # Do predictions

  if(new_season){
    
    x <- final.elos(elo.data)
    regress_custom <- function(elo, to, by){
      elo + (by * (to - elo)) 
    }
    
    y <- regress_custom(x, 1500, carryOver)
    
  }

  predictions_raw <- fixture %>%
    mutate(
      Day = format(Date, "%a, %d"),
      Time = format(Date, "%H:%M"),
      Probability = round(predict(elo.data, newdata = fixture), 3),
      Prediction = round(map_outcome_to_margin(Probability, B = B), 1),
      Result = case_when(
        Probability > 0.5 ~ paste(Home.Team, "by", round(Prediction, 0)),
        Probability < 0.5 ~ paste(Away.Team, "by", -round(Prediction, 0)),
        TRUE ~ "Draw"
      )
    ) 
  
  predictions <- predictions_raw %>% 
    select(Season, Game, Date, Day, Time, Round.Number, Venue, Home.Team, 
           Away.Team, Prediction, Probability, Result) 
  
  return(predictions)
}



