# new_elo_model.R
#
# Clean ELO implementation replacing 3-elo-run.R
#
# Key design decisions (evidence-based, see tune_new_elo.R):
#   - Win/loss updates only (margin adds noise in high-variance AFL scoring)
#   - Venue experience LOG RATIO drives all location-based advantage
#     (home teams avg 44 games at venue vs 7 for away — asymmetry is real)
#   - No separate home factor, interstate, or rest terms — all tested, none added signal
#   - Finals don't update ratings (knockouts are noisy, rematches are common)
#
# Parameters (5 total, down from 8):
#   v             - venue familiarity coefficient (applied to log ratio of experience)
#   base_k        - base learning rate
#   carryOver     - fraction of rating retained across offseason (0=full regression, 1=none)
#   finals_k_mult - K multiplier for finals (0 = don't update from finals)
#   B             - sigmoid steepness (also controls margin scale for predictions)

`%||%` <- function(a, b) if (!is.null(a)) a else b

# ── Helpers ───────────────────────────────────────────────────────────────────

elo_sigmoid     <- function(x, B) 1 / (1 + exp(-B * x))
elo_sigmoid_inv <- function(p, B) -log((1 - p) / p) / B

# FiveThirtyEight MOV correction (retained for use_margin=TRUE mode)
mov_mult <- function(margin, elo_diff) {
  log(abs(margin) + 1) * (2.2 / (abs(elo_diff) * 0.001 + 2.2))
}

# ── Core ELO runner ───────────────────────────────────────────────────────────
# Processes games in strict chronological order.
# All teams initialised at 1500.
# Season regression fires on the first game of each new season.
#
# use_margin: if FALSE (default), uses binary win/loss outcome only.
#             if TRUE, uses FiveThirtyEight MOV multiplier.

run_new_elo <- function(results, params, use_margin = FALSE) {
  
  v             <- params$v
  base_k        <- params$base_k
  carryOver     <- params$carryOver
  B             <- params$B
  finals_k_mult <- params$finals_k_mult %||% 0
  
  results <- results %>% arrange(Date, Game)
  
  teams   <- unique(c(results$Home.Team, results$Away.Team))
  ratings <- setNames(rep(1500.0, length(teams)), teams)
  
  n <- nrow(results)
  
  home_elo_pre  <- numeric(n)
  away_elo_pre  <- numeric(n)
  home_elo_post <- numeric(n)
  away_elo_post <- numeric(n)
  prob_out      <- numeric(n)
  
  current_season <- results$Season[1]
  
  for (i in seq_len(n)) {
    
    season    <- results$Season[i]
    home_team <- results$Home.Team[i]
    away_team <- results$Away.Team[i]
    
    # Season regression — fires on first game of each new season
    if (season != current_season) {
      ratings        <- 1500 + (ratings - 1500) * carryOver
      current_season <- season
    }
    
    # Expansion teams initialise at 1500
    if (is.na(ratings[home_team])) ratings[home_team] <- 1500
    if (is.na(ratings[away_team])) ratings[away_team] <- 1500
    
    home_r <- ratings[[home_team]]
    away_r <- ratings[[away_team]]
    
    # Venue experience log ratio
    # Positive when home team is more familiar with the venue.
    # Goes to zero at a neutral venue (equal experience both sides).
    home_exp  <- max(results$Home.Venue.Exp[i], 1)
    away_exp  <- max(results$Away.Venue.Exp[i], 1)
    venue_adj <- v * log(home_exp / away_exp)
    
    elo_diff        <- home_r - away_r + venue_adj
    expected        <- elo_sigmoid(elo_diff, B)
    
    home_elo_pre[i] <- home_r
    away_elo_pre[i] <- away_r
    prob_out[i]     <- expected
    
    # Only update on completed games
    if (!is.na(results$Home.Points[i])) {
      
      margin <- results$Home.Points[i] - results$Away.Points[i]
      actual <- ifelse(margin > 0, 1, ifelse(margin < 0, 0, 0.5))
      
      is_final <- "Round.Type" %in% names(results) &&
        !is.na(results$Round.Type[i]) &&
        results$Round.Type[i] == "Finals"
      
      k     <- base_k * ifelse(is_final, finals_k_mult, 1.0)
      k_eff <- if (use_margin) k * mov_mult(margin, elo_diff) else k
      
      update <- k_eff * (actual - expected)
      
      ratings[[home_team]] <- home_r + update
      ratings[[away_team]] <- away_r - update
    }
    
    home_elo_post[i] <- ratings[[home_team]]
    away_elo_post[i] <- ratings[[away_team]]
  }
  
  results_out <- results %>%
    mutate(
      Home.ELO_pre = home_elo_pre,
      Away.ELO_pre = away_elo_pre,
      Home.ELO     = home_elo_post,
      Away.ELO     = away_elo_post,
      Probability  = prob_out,
      Prediction   = ceiling(elo_sigmoid_inv(
        pmin(pmax(prob_out, 0.001), 0.999), B))
    )
  
  list(
    results       = results_out,
    final_ratings = ratings,
    params        = params,
    use_margin    = use_margin
  )
}

# ── Margin calibration ────────────────────────────────────────────────────────
# The raw sigmoid inverse systematically overestimates margins for strong
# favourites because it assumes actual margins follow the same sigmoid shape
# as win probability. They don't — AFL margins are much noisier.
#
# Fix: fit a simple OLS regression of actual_margin ~ raw_predicted_margin
# on all historical completed games (forced through origin so 0 stays 0),
# then apply the scaling factor at prediction time.
#
# Usage in weekly_data_process.R:
#   elo_dat      <- run_new_elo(dat$results, params)
#   margin_cal   <- fit_margin_calibration(elo_dat$results)
#   # then in predictions mutate:
#   Prediction   <- calibrate_margin(raw_prediction, margin_cal)

fit_margin_calibration <- function(model_results) {
  completed <- model_results %>%
    filter(!is.na(Home.Points)) %>%
    mutate(actual_margin = Home.Points - Away.Points)
  
  # Fit directly on probability — skips the sigmoid inverse entirely
  # poly(..., 3) captures the S-shape: steep in the middle, flattening at extremes
  lm(actual_margin ~ poly(Probability, 3), data = completed)
}

calibrate_margin <- function(probability, calibration_fit) {
  unname(predict(calibration_fit,
                 newdata = data.frame(Probability = probability)))
}

# ── Prediction functions ──────────────────────────────────────────────────────

# Predict win probability using model's current ratings.
# Replaces: predict(elo.data, newdata = fixture)
predict_new_elo <- function(model, newdata) {
  predict_with_ratings(model$params, newdata, model$final_ratings)
}

# Predict using a supplied ratings vector — used for perturbed sim ELOs.
# Replaces: elo.prob(form, data = fixture, elos = perturbed_elos)
predict_with_ratings <- function(params, newdata, ratings) {
  home_exp <- pmax(newdata$Home.Venue.Exp, 1)
  away_exp <- pmax(newdata$Away.Venue.Exp, 1)
  
  home_r   <- ratings[newdata$Home.Team]
  away_r   <- ratings[newdata$Away.Team]
  home_r[is.na(home_r)] <- 1500
  away_r[is.na(away_r)] <- 1500
  
  venue_adj <- params$v * log(home_exp / away_exp)
  elo_diff  <- home_r - away_r + venue_adj
  
  elo_sigmoid(elo_diff, params$B)
}

# ── Simulation helpers ────────────────────────────────────────────────────────

# Get current ratings as named vector.
# Replaces: final.elos(elo.data)
get_final_elos <- function(model) {
  model$final_ratings
}

# Perturb ratings for simulation uncertainty.
# Replaces: perturb_elos() in 4-sims.R
# sd=85 reflects typical ELO uncertainty range (~1 win probability tier)
perturb_elos_new <- function(model, sd = 85) {
  ratings   <- get_final_elos(model)
  perturbed <- ratings + rnorm(length(ratings), mean = 0, sd = sd)
  perturbed + 1500 - mean(perturbed)  # re-centre around 1500
}

# ── Long format output ────────────────────────────────────────────────────────
# One row per team per game — same structure as original elo output used downstream.

elo_to_long <- function(results_with_elo) {
  bind_rows(
    results_with_elo %>%
      select(Date, Game, Round, Round.Number,
             Team    = Home.Team,
             ELO     = Home.ELO,
             ELO_pre = Home.ELO_pre) %>%
      mutate(Status = "Home"),
    results_with_elo %>%
      select(Date, Game, Round, Round.Number,
             Team    = Away.Team,
             ELO     = Away.ELO,
             ELO_pre = Away.ELO_pre) %>%
      mutate(Status = "Away")
  ) %>%
    mutate(ELO = as.numeric(ELO), ELO_pre = as.numeric(ELO_pre)) %>%
    group_by(Team) %>%
    arrange(Game)
}