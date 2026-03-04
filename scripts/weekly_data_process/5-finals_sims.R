
# Helper functions -------------------------------------------------------

create_finals_fixture <- function(week = 1, season, last_game_num, last_round) {
  
  if (week == 1) {  # NEW: Wildcard round
    dat <- tibble(
      Game      = (last_game_num + 1):(last_game_num + 2),
      Game_Name = c("WC1", "WC2"))
  }
  
  if (week == 2) {  # Was week 1: QF + EF
    dat <- tibble(
      Game      = (last_game_num + 1):(last_game_num + 4),
      Game_Name = c("QF1", "QF2", "EF1", "EF2"))
  }
  
  if (week == 3) {  # Was week 2: SF
    dat <- tibble(
      Game      = (last_game_num + 1):(last_game_num + 2),
      Game_Name = c("SF1", "SF2"))
  }
  
  if (week == 4) {  # Was week 3: PF
    dat <- tibble(
      Game      = (last_game_num + 1):(last_game_num + 2),
      Game_Name = c("PF1", "PF2"))
  }
  
  if (week == 5) {  # Was week 4: GF
    dat <- tibble(
      Game      = last_game_num + 1,
      Game_Name = c("GF"))
  }
  
  dat %>%
    mutate(
      Season      = season,
      Finals_week = week,
      Round       = last_round + week
    )
}

simulate_finals <- function(form, fixture, elos, sim_num) {
  probs <- map2(
    .x = elos,
    .y = fixture,
    .f = ~ elo::elo.prob(form, data = .y, elos = .x)
  )
  
  map2(
    .x = fixture,
    .y = probs,
    .f = ~ mutate(.x,
                  Probability = .y,
                  Margin      = ceiling(map_outcome_to_margin(Probability, B = B)),
                  Win         = rbinom(n(), 1, Probability))
  ) %>%
    map2(.y = 1:sim_num, ~ mutate(.x, Sim = .y))
}

add_formula_variables <- function(fixture) {
  fixture %>%
    mutate(
      Venue           = "",
      Home.Venue.Exp  = 1,
      Away.Venue.Exp  = 1,
      Home.Interstate = FALSE,
      Away.Interstate = FALSE,
      Home.Factor     = 1,
      Away.Factor     = 0
    )
}

# Name helpers: map ladder position to game name (used when finals_started = TRUE)

get_wc_names <- function(ladder_pos) {
  case_when(
    ladder_pos == 7  ~ "WC1",
    ladder_pos == 10 ~ "WC1",
    ladder_pos == 8  ~ "WC2",
    ladder_pos == 9  ~ "WC2",
    TRUE ~ ""
  )
}

get_wk2_names <- function(ladder_pos) {  # QF/EF week
  case_when(
    ladder_pos == 1 ~ "QF1",
    ladder_pos == 4 ~ "QF1",
    ladder_pos == 2 ~ "QF2",
    ladder_pos == 3 ~ "QF2",
    ladder_pos == 5 ~ "EF1",
    ladder_pos == 6 ~ "EF2",
    TRUE ~ ""
  )
}

get_wk3_names <- function(ladder_pos) {  # SF week
  case_when(
    ladder_pos == 1 ~ "SF1",
    ladder_pos == 4 ~ "SF1",
    ladder_pos == 2 ~ "SF2",
    ladder_pos == 3 ~ "SF2",
    TRUE ~ ""
  )
}

get_wk4_names <- function(ladder_pos) {  # PF week
  case_when(
    ladder_pos == 1 ~ "PF1",
    ladder_pos == 4 ~ "PF1",
    ladder_pos == 2 ~ "PF2",
    ladder_pos == 3 ~ "PF2",
    TRUE ~ ""
  )
}

# Main simulation function -----------------------------------------------

do_finals_sims <- function(sim_data_all,
                           game_dat,
                           sim_num,
                           elo.data,
                           sim_elo_perterbed,    # passed in from do_sims(); no longer recomputed
                           last_round,
                           ladder            = NULL,
                           home_away_ongoing = FALSE,
                           finals_started    = FALSE,
                           finals_week       = NULL,
                           finals_results    = NULL) {
  
  cli_progress_step("Setting up Finals Sims")
  
  form <- elo:::clean_elo_formula(stats::terms(elo.data))
  
  # PERF FIX: use passed-in perturbed ELOs when available rather than recomputing.
  # Original code always recomputed, discarding sim_elo_perterbed entirely.
  if (is.null(sim_elo_perterbed)) {
    finals_elos <- 1:sim_num %>%
      rep_along(list(elo.data)) %>%
      map(perturb_elos)
  } else {
    finals_elos <- sim_elo_perterbed[1:sim_num]
  }
  
  if (!is.null(finals_results)) {
    finals_results <- finals_results %>%
      mutate(
        Finals_week = Round - min(Round) + 1,
        Win         = as.numeric(Margin > 0)
      )
  }
  
  if (is.null(finals_week)) finals_week <- 0
  
  # Build sim ladders (Top 10) ---------------------------------------------
  
  if (is.null(ladder) | home_away_ongoing) {
    sim_ladder <- sim_data_all %>%
      filter(Top.10) %>%                  # was Top.8
      arrange(Sim, Rank) %>%
      group_by(Sim) %>%
      select(Sim, Team, Rank) %>%
      group_split() %>%
      .[1:sim_num]
  } else {
    sim_ladder <- ladder %>%
      rename(Team = team.name, Rank = position) %>%
      select(Team, Rank) %>%
      filter(Rank <= 10) %>%              # was < 9
      arrange(Rank)
    
    sim_ladder <- 1:sim_num %>%
      map(~ mutate(sim_ladder, Sim = .x))
  }
  
  # Week 1 — Wildcard Round ------------------------------------------------
  # NEW: 7th hosts 10th (WC1), 8th hosts 9th (WC2). Teams 1-6 have a bye.
  
  cli_progress_step("Simulating Finals Week 1 (Wildcard)")
  
  if (finals_week < 1) {
    
    wk1_base_fixture <- create_finals_fixture(
      week          = 1,
      season        = last(game_dat$Season),
      last_game_num = last(game_dat$Game),
      last_round    = last_round
    )
    
    wk1_fixture <- sim_ladder %>%
      map(~ wk1_base_fixture %>%
            mutate(
              Home.Team = .x$Team[c(7, 8)],   # 7th and 8th are home
              Away.Team = .x$Team[c(10, 9)]   # vs 10th and 9th
            )) %>%
      map(add_formula_variables)
    
    wk1_results <- simulate_finals(form, wk1_fixture, finals_elos, sim_num)
    
  } else {
    # Finals already started — use actual results
    wk1_results <- finals_results %>%
      filter(Finals_week == 1) %>%
      mutate(Game_Name = get_wc_names(Rank))
    
    wk1_results <- 1:sim_num %>%
      map(~ mutate(wk1_results, Sim = .x))
  }
  
  # Extract WC winners/losers (needed for EF matchups in Week 2)
  wk1_teams <- wk1_results %>%
    map(~ mutate(.x,
                 Winner = ifelse(Win == 1, Home.Team, Away.Team),
                 Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
          select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  
  # Week 2 — Qualifying + Elimination Finals --------------------------------
  # QF1: 1 vs 4,  QF2: 2 vs 3
  # EF1: 5 vs winner of WC2 (8/9 game = lower-seeded WC winner)
  # EF2: 6 vs winner of WC1 (7/10 game = higher-seeded WC winner)
  
  cli_progress_step("Simulating Finals Week 2 (QF/EF)")
  
  if (finals_week < 2) {
    
    wk2_base_fixture <- create_finals_fixture(
      week          = 2,
      season        = last(wk1_results[[1]]$Season),
      last_game_num = last(wk1_results[[1]]$Game),
      last_round    = last(wk1_results[[1]]$Round)
    )
    
    wk2_fixture <- map2(sim_ladder, wk1_teams, function(ldr, wc) {
      wc1_winner <- wc$Winner[wc$Game_Name == "WC1"]  # higher-seeded WC winner
      wc2_winner <- wc$Winner[wc$Game_Name == "WC2"]  # lower-seeded WC winner
      wk2_base_fixture %>%
        mutate(
          Home.Team = c(ldr$Team[1], ldr$Team[2], ldr$Team[5], ldr$Team[6]),
          Away.Team = c(ldr$Team[4], ldr$Team[3], wc2_winner,  wc1_winner)
        )
    }) %>%
      map(add_formula_variables)
    
    wk2_results <- simulate_finals(form, wk2_fixture, finals_elos, sim_num)
    
  } else {
    wk2_results <- finals_results %>%
      filter(Finals_week == 2) %>%
      mutate(Game_Name = get_wk2_names(Rank))
    
    wk2_results <- 1:sim_num %>%
      map(~ mutate(wk2_results, Sim = .x))
    
    wk3_teams <- wk2_results %>%
      map(~ mutate(.x,
                   Winner = ifelse(Win == 1, Home.Team, Away.Team),
                   Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
            select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  }
  
  wk2_teams <- wk2_results %>%
    map(~ mutate(.x,
                 Winner = ifelse(Win == 1, Home.Team, Away.Team),
                 Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
          select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  
  # Week 3 — Semi Finals ----------------------------------------------------
  # SF1: loser QF1 (home) vs winner EF1
  # SF2: loser QF2 (home) vs winner EF2
  
  cli_progress_step("Simulating Finals Week 3 (Semi-Finals)")
  
  if (finals_week < 3) {
    
    wk3_base_fixture <- create_finals_fixture(
      week          = 3,
      season        = last(wk2_results[[1]]$Season),
      last_game_num = last(wk2_results[[1]]$Game),
      last_round    = last(wk2_results[[1]]$Round)
    )
    
    wk3_fixture <- wk2_teams %>%
      map(~ wk3_base_fixture %>%
            mutate(
              Home.Team = .x$Loser[c(which(.x$Game_Name  == "QF1"),
                                     which(.x$Game_Name  == "QF2"))],
              Away.Team = .x$Winner[c(which(.x$Game_Name == "EF1"),
                                      which(.x$Game_Name == "EF2"))]
            )) %>%
      map(add_formula_variables)
    
    wk3_results <- simulate_finals(form, wk3_fixture, finals_elos, sim_num)
    
  } else {
    wk3_results <- finals_results %>%
      filter(Finals_week == 3) %>%
      mutate(Game_Name = get_wk3_names(Rank))
    
    wk3_results <- 1:sim_num %>%
      map(~ mutate(wk3_results, Sim = .x))
    
    wk4_teams <- wk3_results %>%
      map(~ mutate(.x,
                   Winner = ifelse(Win == 1, Home.Team, Away.Team),
                   Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
            select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  }
  
  wk3_teams <- wk3_results %>%
    map2(.y = wk2_teams,
         ~ mutate(.x,
                  Winner = ifelse(Win == 1, Home.Team, Away.Team),
                  Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
           select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
           bind_rows(.y) %>%
           distinct())
  
  # Week 4 — Preliminary Finals ---------------------------------------------
  # PF1: winner QF1 (home) vs winner SF2
  # PF2: winner QF2 (home) vs winner SF1
  
  cli_progress_step("Simulating Finals Week 4 (Preliminary Finals)")
  
  if (finals_week < 4) {
    
    wk4_base_fixture <- create_finals_fixture(
      week          = 4,
      season        = last(wk3_results[[1]]$Season),
      last_game_num = last(wk3_results[[1]]$Game),
      last_round    = last(wk3_results[[1]]$Round)
    )
    
    wk4_fixture <- wk3_teams %>%
      map(~ wk4_base_fixture %>%
            mutate(
              Home.Team = .x$Winner[c(which(.x$Game_Name == "QF1"),
                                      which(.x$Game_Name == "QF2"))],
              Away.Team = .x$Winner[c(which(.x$Game_Name == "SF2"),
                                      which(.x$Game_Name == "SF1"))]
            )) %>%
      map(add_formula_variables)
    
    wk4_results <- simulate_finals(form, wk4_fixture, finals_elos, sim_num)
    
  } else {
    wk4_results <- finals_results %>%
      filter(Finals_week == 4) %>%
      mutate(Game_Name = get_wk4_names(Rank))
    
    wk4_results <- 1:sim_num %>%
      map(~ mutate(wk4_results, Sim = .x))
  }
  
  wk4_teams <- wk4_results %>%
    map2(.y = wk3_teams,
         ~ mutate(.x,
                  Winner = ifelse(Win == 1, Home.Team, Away.Team),
                  Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
           select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
           bind_rows(.y))
  
  # Week 5 — Grand Final ----------------------------------------------------
  
  cli_progress_step("Simulating Finals Week 5 (Grand Final)")
  
  if (finals_week < 5) {
    
    wk5_base_fixture <- create_finals_fixture(
      week          = 5,
      season        = last(wk4_results[[1]]$Season),
      last_game_num = last(wk4_results[[1]]$Game),
      last_round    = last(wk4_results[[1]]$Round)
    )
    
    wk5_fixture <- wk4_teams %>%
      map(~ wk5_base_fixture %>%
            mutate(
              Home.Team = .x$Winner[which(.x$Game_Name == "PF1")],
              Away.Team = .x$Winner[which(.x$Game_Name == "PF2")]
            )) %>%
      map(add_formula_variables)
    
    wk5_results <- simulate_finals(form, wk5_fixture, finals_elos, sim_num)
    
  } else {
    wk5_results <- finals_results %>%
      filter(Finals_week == 5) %>%
      mutate(Game_Name = "GF")
    
    wk5_results <- 1:sim_num %>%
      map(~ mutate(wk5_results, Sim = .x))
  }
  
  # Combine and summarise --------------------------------------------------
  
  cli_progress_step("Combining finals sims data")
  
  final_teams <- wk5_results %>%
    map2(.y = wk4_teams,
         ~ mutate(.x,
                  Winner = ifelse(Win == 1, Home.Team, Away.Team),
                  Loser  = ifelse(Win == 0, Home.Team, Away.Team)) %>%
           select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
           bind_rows(.y))
  
  final_results <- final_teams %>%
    map(~ .x %>%
          pivot_longer(c(Winner, Loser),
                       names_to  = "Result",
                       values_to = "Team") %>%
          group_by(Team) %>%
          mutate(max_week = max(Finals_week)))
  
  final_game <- final_results %>%
    map(~ .x %>%
          filter(max_week == Finals_week) %>%
          mutate(
            Game = str_remove(Game_Name, "[0-9]"),
            Game = ifelse(Game == "GF" & Result == "Winner", "Premier", Game)
          ) %>%
          select(Season, Team, Game, Finals_week, Sim))
  
  finals_dat <- list(
    final_teams   = final_teams,
    final_results = final_results,
    final_game    = final_game
  )
  
  return(finals_dat)
}

combine_finals_sims <- function(final_game,
                                sim_data_summary,
                                results,
                                elo.data,
                                sim_num               = 1,
                                ladder                = NULL,
                                home_and_away_complete = FALSE) {
  
  cli_progress_step("Combining Finals Sims")
  
  # PERF FIX: bind_rows(list) is O(n) vs reduce(bind_rows) which is O(n^2).
  # With sim_num = 10000 this makes a substantial difference.
  final_summary_long <- bind_rows(final_game)
  
  final_summary_wide <- final_summary_long %>%
    group_by(Season, Team) %>%
    summarise(
      win_league  = sum(Game == "Premier"),
      make_gf     = sum(Finals_week >= 5),   # reached GF week
      make_prelim = sum(Finals_week >= 4),   # reached PF week
      make_semis  = sum(Finals_week >= 3),   # survived week 2 (QF winners' bye counts)
      make_qf_ef  = sum(Finals_week >= 2),   # reached QF/EF week (top 6 bye + WC winners)
      make_finals = n()                      # top 10
    ) %>%
    mutate_if(is.numeric, ~ . / sim_num)
  
  final_summary_wide[is.na(final_summary_wide)] <- 0
  
  if (home_and_away_complete) {
    final_ladder <- ladder %>%
      mutate(Margin = pointsFor - pointsAgainst) %>%
      rename(
        Rank   = position,
        Team   = team.name,
        Season = season,
        Round  = round_number,
        Wins   = thisSeasonRecord.winLossRecord.wins,
        Perc   = thisSeasonRecord.percentage
      ) %>%
      select(Rank, Team, Season, Round, Margin, Wins, Perc) %>%
      mutate(
        Top.10 = as.numeric(Rank <= 10),   # was Top.8 / Rank <= 8
        Top.4  = as.numeric(Rank <= 4),
        Top.2  = as.numeric(Rank <= 2),
        Top.1  = as.numeric(Rank == 1)
      )
  } else {
    final_ladder <- sim_data_summary %>%
      filter(Season == max(final_summary_wide$Season)) %>%
      filter(Round == max(Round))
  }
  
  last_completed_round <- last(results$Round)
  
  sims_combined <- final_ladder %>%
    left_join(final_summary_wide, by = c("Team", "Season")) %>%
    mutate(Round = last_completed_round)
  
  # Add ELO
  elos <- elo.data %>%
    as.matrix() %>%
    tail(2) %>%
    t() %>%
    as.data.frame() %>%
    rownames_to_column("Team")
  
  names(elos) <- c("Team", "elo.old", "elo")
  
  elos <- elos %>%
    mutate(elo.change = elo - elo.old)
  
  sims_combined <- sims_combined %>%
    left_join(elos)
  
  sims_combined[is.na(sims_combined)] <- 0
  
  if (!is.null(ladder)) {
    win_loss <- ladder %>%
      rename(
        Team   = team.name,
        Season = season,
        Wins   = thisSeasonRecord.winLossRecord.wins,
        Losses = thisSeasonRecord.winLossRecord.losses,
        Draws  = thisSeasonRecord.winLossRecord.draws
      ) %>%
      mutate(Form = ifelse(Draws > 0,
                           paste0(Wins, "-", Losses, "-", Draws),
                           paste0(Wins, "-", Losses))) %>%
      select(Team, Season, Form)
  } else {
    win_loss <- sims_combined %>%
      select(Team, Season) %>%
      mutate(Form = "-")
  }
  
  sims_combined <- sims_combined %>%
    left_join(win_loss, by = c("Team", "Season"))
  
  list(
    sims_combined = sims_combined,
    win_loss      = win_loss
  )
}