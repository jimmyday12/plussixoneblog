# 4-sims.R
# Updated to use new_elo_model.R instead of elo package.
# perturb_elos removed — use perturb_elos_new() from new_elo_model.R
# elo.prob removed    — use predict_with_ratings() from new_elo_model.R
# margin calc updated — use calibrate_margin() from new_elo_model.R

do_sims <- function(sim_num, results, fixture, elo_dat, params, margin_cal) {
  
  sim_res <- results %>%
    filter(year(Date) == min(fixture$Season)) %>%
    mutate(
      Season.Game = Game - min(Game) + 1,
      Round       = Round.Number
    )
  
  remaining_fixture <- fixture
  
  sims    <- 1:sim_num
  n_games <- nrow(remaining_fixture)
  
  # PERF: row-repeat + single mutate vs map_df creating 10k copies one at a time
  res <- sim_res[rep(seq_len(nrow(sim_res)), sim_num), ] %>%
    mutate(Sim = rep(sims, each = nrow(sim_res)))
  
  # Perturb ELO ratings for each simulation
  sim_elo_perterbed <- map(sims, ~ perturb_elos_new(elo_dat))
  
  # PERF: compute all probs as list of vectors, build one dataframe in one shot
  all_probs <- sim_elo_perterbed %>%
    map(~ predict_with_ratings(params, remaining_fixture, .x))
  
  # With this:
  sim_data <- remaining_fixture[rep(seq_len(n_games), sim_num), ] %>%
    mutate(
      Sim        = rep(sims, each = n_games),
      Probability = unlist(all_probs),
      Home_Win   = rbinom(n(), 1, Probability),
      Margin     = ceiling(abs(calibrate_margin(Probability, margin_cal))) * 
        ifelse(Home_Win == 1, 1, -1)
    ) %>%
    select(-Home_Win) %>%
    bind_rows(res)
  
  list(
    sim_data          = sim_data,
    sim_elo_perterbed = sim_elo_perterbed
  )
}

# Summarise simulated data ------------------------------------------------

win_calc <- function(x) case_when(x == 0 ~ 0.5, x > 0 ~ 1, TRUE ~ 0)

combine_sim_dat <- function(sim_data, results = NULL) {
  
  sim_data_all <- sim_data %>%
    pivot_longer(c(Home.Team, Away.Team), names_to = "Status", values_to = "Team") %>%
    mutate(
      Margin = ifelse(Status == "Home.Team", Margin, -Margin),
      Win    = win_calc(Margin)
    ) %>%
    group_by(Sim, Team) %>%
    summarise(
      Wins   = sum(Win),
      Margin = sum(Margin),
      Games  = n()
    )
  
  if (!is.null(results)) {
    sim_data_all <- calculate_perc(results, sim_data_all)
  } else {
    sim_data_all$Perc <- 100
  }
  
  sim_data_all %>%
    group_by(Sim) %>%
    arrange(desc(Perc), desc(Margin)) %>%
    mutate(
      Rank   = row_number(desc(Wins)),
      Top.10 = Rank <= 10,
      Top.4  = Rank < 5,
      Top.2  = Rank < 3,
      Top.1  = Rank == 1
    ) %>%
    arrange(Rank)
}

calculate_sim_perc <- function(sim_dat_all, season, round, sim_num) {
  sim_dat_all %>%
    group_by(Team) %>%
    dplyr::summarise(
      Season = season,
      Round  = round,
      Margin = mean(Margin),
      Wins   = mean(Wins),
      Perc   = mean(Perc),
      Top.10 = sum(Top.10) / sim_num,
      Top.4  = sum(Top.4)  / sim_num,
      Top.2  = sum(Top.2)  / sim_num,
      Top.1  = sum(Top.1)  / sim_num
    )
}

combine_past_sims <- function(sim_data_summary, round, season, past_sims) {
  past_sims$sim_data_summary %>%
    filter(!(Round == round & Season == season)) %>%
    bind_rows(sim_data_summary)
}

count_sims <- function(sim_data_all, sim_data_summary, sim_num, season, round, past_sims) {
  
  simCount <- sim_data_all %>%
    ungroup() %>%
    select(Team, Rank) %>%
    table() %>%
    as.data.frame() %>%
    group_by(Team) %>%
    mutate(Freq = Freq / sim_num * 100)
  
  simCount$Freq[simCount$Freq == 0] <- NA
  
  simWins <- sim_data_summary %>%
    filter(Season == season) %>%
    filter(Round == round) %>%
    arrange(Wins)
  
  simCount$Team <- factor(simCount$Team, levels = simWins$Team)
  
  simCount <- simCount %>%
    group_by(Team) %>%
    mutate(
      order = dense_rank(desc(Freq)),
      txt   = case_when(
        Freq < 1 ~ "<1",
        Freq > 1 ~ as.character(round(Freq, 0)),
        TRUE     ~ ""
      )
    ) %>%
    arrange(Team, order)
  
  simCount <- simCount %>%
    mutate(
      Season = last(sim_data_summary$Season),
      Round  = last(sim_data_summary$Round)
    )
  
  if ("simCount" %in% names(past_sims)) {
    simCount <- past_sims$simCount %>%
      filter(!(Round == round & Season == season)) %>%
      bind_rows(simCount)
  }
}

predict_perc <- function(games, pf, pa, pf_sd, pa_sd, games_left, elo_marg) {
  pf_avg <- pf / games
  pa_avg <- pa / games
  
  act_marg <- pf - pa
  
  if (is.na(pf_sd)) pf_sd <- 20
  if (is.na(pa_sd)) pa_sd <- 20
  
  pred_rem_f <- sum(rnorm(games_left, pf_avg, pf_sd))
  pred_rem_a <- sum(rnorm(games_left, pa_avg, pa_sd))
  
  elo_rem_marg  <- elo_marg - act_marg
  pred_rem_marg <- pred_rem_f - pred_rem_a
  diff          <- elo_rem_marg - pred_rem_marg
  
  adj_rem_f <- pred_rem_f
  adj_rem_a <- adj_rem_f - elo_rem_marg
  
  adj_score_f <- pf + adj_rem_f
  adj_score_a <- pa + adj_rem_a
  
  adj_perc <- adj_score_f / adj_score_a * 100
  
  return(adj_perc)
}

calculate_perc <- function(results, sim_data_all) {
  
  results_ladder <- results %>%
    pivot_longer(c(Home.Team, Away.Team), names_to = "Status", values_to = "Team") %>%
    mutate(
      Margin         = ifelse(Status == "Home.Team", Margin, -Margin),
      Points_for     = ifelse(Status == "Home.Team", Home.Points, Away.Points),
      Points_against = ifelse(Status == "Home.Team", Away.Points, Home.Points),
      Win            = win_calc(Margin)
    ) %>%
    filter(!is.na(Points_for)) %>%
    group_by(Team) %>%
    summarise(
      games_sum  = n(),
      margin_sum = sum(Margin),
      pf_sum     = sum(Points_for),
      pf_sd      = sd(Points_for, na.rm = TRUE),
      pa_sum     = sum(Points_against),
      pa_sd      = sd(Points_against, na.rm = TRUE)
    ) %>%
    left_join(sim_data_all %>% ungroup() %>% select(Sim, Team, Margin, Games)) %>%
    group_by(Team, Sim)
  
  results_marg <- results_ladder %>%
    mutate(Perc = predict_perc(
      games_sum,
      pf         = pf_sum,
      pa         = pa_sum,
      pf_sd      = pf_sd,
      pa_sd      = pa_sd,
      games_left = Games - games_sum,
      elo_marg   = Margin
    )) %>%
    select(Sim, Team, Margin, Perc)
  
  sim_data_all %>%
    left_join(results_marg)
}