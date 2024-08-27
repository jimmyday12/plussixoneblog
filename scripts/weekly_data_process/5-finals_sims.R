# # Finals Sims

# Helper functions ---------------
create_finals_fixture <- function(week = 1, season, last_game_num, last_round) {
  if(week == 1) {
    dat <- tibble(
      Game = (last_game_num+1):(last_game_num+4),
      Game_Name = c("QF1", "QF2", "EF1", "EF2"))
  }
  
  if(week == 2){
    dat <- tibble(
      Game = (last_game_num+1):(last_game_num+2),
      Game_Name = c("SF1", "SF2"))
  }
  if(week == 3){
    dat <- tibble(
      Game = (last_game_num+1):(last_game_num+2),
      Game_Name = c("PF1", "PF2"))
  }
  
  if(week == 4){
    dat <- tibble(
      Game = (last_game_num+1),
      Game_Name = c("GF"))
  }
  
  dat %>%
    mutate(Season = season,
           Finals_week = week,
           Round = last_round + week)
}

simulate_finals <- function(form, fixture, elos, sim_num){
  probs <- elos %>%
    map2(.y = fixture, 
         .f =  ~elo::elo.prob(form, data = .y, elos = .x))
  
  map2(.x = fixture, 
       .y = probs, 
       .f = ~mutate(.x, 
                    Probability = .y,
                    Margin = ceiling(map_outcome_to_margin(Probability, B = B)),
                    Win = rbinom(n(), 1, Probability))) %>%
    map2(.y = 1:sim_num,
         ~mutate(.x, 
                 Sim = .y)) 
}

add_formula_variables <- function(fixture) {
  fixture %>%
    mutate(Venue = "",
           Home.Venue.Exp = 1,
           Away.Venue.Exp = 1,
           Home.Interstate = FALSE,
           Away.Interstate = FALSE,
           Home.Factor = 1,
           Away.Factor = 0)
}

get_wk1_names <- function(ladder_pos) {
  case_when(
    ladder_pos == 1 ~ "QF1",
    ladder_pos == 2 ~ "QF2",
    ladder_pos == 5 ~ "EF1",
    ladder_pos == 6 ~ "EF2",
    TRUE ~ "")
}

get_wk2_names <- function(ladder_pos) {
  case_when(
    ladder_pos == 1 ~ "SF1",
    ladder_pos == 4 ~ "SF1",
    ladder_pos == 2 ~ "SF2",
    ladder_pos == 3 ~ "SF2",
    TRUE ~ "")
}

get_wk3_names <- function(ladder_pos) {
  case_when(
    ladder_pos == 1 ~ "PF1",
    ladder_pos == 4 ~ "PF1",
    ladder_pos == 2 ~ "PF2",
    ladder_pos == 3 ~ "PF2",
    TRUE ~ "")
}

# Add elo
do_finals_sims <- function(sim_data_all, 
                           game_dat, 
                           sim_num, 
                           elo.data,
                           sim_elo_perterbed,
                           last_round,
                           ladder = NULL,
                           home_away_ongoing = FALSE,
                           finals_started = FALSE,
                           finals_week = NULL,
                           finals_results = NULL){
  
  cli_progress_step("Setting up Finals Sims")
  
  form <- elo:::clean_elo_formula(stats::terms(elo.data))
  
  # This is inefficient
  sim_elo_perterbed <- 1:sim_num %>%
    rep_along(list(elo.data)) %>%
    map(perturb_elos) 
  
  finals_elos <- sim_elo_perterbed[1:sim_num]
  
  if (!is.null(finals_results)){
    finals_results <- finals_results %>%
      mutate(Finals_week = Round - min(Round) + 1,
             Win = as.numeric(Margin > 0))
    
  }
    
  #finals_results <- finals_results %>%
  #  left_join(sim_ladder[1], by = c("Home.Team" = "Team"))
  
  if (is.null(finals_week)) finals_week <- 0
  # Week 1 -----------------------------------------------------------------------
  # Step 1 - get top 8
  
  if (is.null(ladder) | home_away_ongoing){
  sim_ladder <- sim_data_all %>%
    filter(Top.8) %>%
    arrange(Sim, Rank) %>%
    group_by(Sim) %>%
    select(Sim, Team, Rank) %>%
    group_split() %>%
    .[1:sim_num]
  
  } else {
    sim_ladder <- ladder %>%
      rename(Team = team.name, Rank = position) %>%
      select(Team, Rank) %>%
      filter(Rank < 9)
    
    sim_ladder <- 1:sim_num %>%
      map(~mutate(sim_ladder, Sim = .x))
    
  }
  
  if(finals_started) {
    finals_results <- finals_results %>%
      left_join(sim_ladder[[1]], by = c("Home.Team" = "Team"))
    
  }
    
 
  
  #game_dat <-  game_dat
  cli_progress_step("Simulating Finals Week 1")
  if (finals_week < 1){

  # Step 2 - create fixture
  wk1_fixture <- create_finals_fixture(week = 1, 
                                       season = last(game_dat$Season),
                                       last_game_num = last(game_dat$Game),
                                       last_round = last_round)
  
  # Step 3 - get the right teams
  wk1_fixture <- sim_ladder %>%
    map(~wk1_fixture %>%
          mutate(Home.Team = .x$Team[c(1,2,5,6)],
                 Away.Team = .x$Team[c(4,3,8,7)]))
  
  # Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
  wk1_fixture <- wk1_fixture %>%
    map(add_formula_variables)
  
  # Step 5 - simulate results
  wk1_results <- simulate_finals(form, wk1_fixture, finals_elos, sim_num)
  
  } else {
    wk1_results <- finals_results %>%
      filter(Finals_week == 1) %>%
      mutate(Game_Name = get_wk1_names(Rank)) 
    
    wk1_results <- 1:sim_num %>%
      map(~mutate(wk1_results, Sim = .x))
    
    wk2_teams <- wk1_results %>%
      map(~mutate(.x,
                  Winner = ifelse(Win == 1, Home.Team, Away.Team),
                  Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
            select(Season, Finals_week, Game_Name, Winner, Loser, Sim))

  }
  
  
  # Week 2 -----------------------------------------------------------------------
  cli_progress_step("Simulating Finals Week 2")
  if (finals_week < 2) {
  
  # Step 1 - get week 2 teams
  wk2_teams <- wk1_results %>%
    map(~mutate(.x,
                Winner = ifelse(Win == 1, Home.Team, Away.Team),
                Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
          select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  
  # Step 2 - create fixture
  wk2_fixture <- create_finals_fixture(week = 2, 
                                       season = last(wk1_results[[1]]$Season),
                                       last_game_num = last(wk1_results[[1]]$Game),
                                       last_round = last(wk1_results[[1]]$Round))
  
  
  # Step 3 - get the right teams
  wk2_fixture <- wk2_teams %>%
    map(~wk2_fixture %>%
          mutate(Home.Team = .x$Loser[c(which(.x$Game_Name == "QF1"), which(.x$Game_Name == "QF2"))],
                 Away.Team = .x$Winner[c(which(.x$Game_Name == "EF1"), which(.x$Game_Name == "EF2"))]))
  
  # Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
  wk2_fixture <- wk2_fixture %>%
    map(add_formula_variables)
  
  
  # Step 5 - simulate results
  wk2_results <- simulate_finals(form, wk2_fixture, finals_elos, sim_num)
  } else {
    wk2_results <- finals_results %>%
      filter(Finals_week == 2) %>%
      mutate(Game_Name = get_wk2_names(Rank))
      
    wk2_results <- 1:sim_num %>%
      map(~mutate(wk2_results, Sim = .x))
    
    wk3_teams <- wk2_results %>%
      map(~mutate(.x,
                  Winner = ifelse(Win == 1, Home.Team, Away.Team),
                  Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
            select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  }
  
  # Week 3 -----------------------------------------------------------------------
  # Step 1 - get week 2 teams
  cli_progress_step("Simulating Finals Week 3")
  if (finals_week < 3) {
  
  wk3_teams <- wk2_results %>%
    map2(.y = wk2_teams, 
         ~mutate(.x,
                 Winner = ifelse(Win == 1, Home.Team, Away.Team),
                 Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
           select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
           bind_rows(.y) %>%
           distinct())
  
  # Step 2 - create fixture
  wk3_fixture <- create_finals_fixture(week = 3, 
                                       season = last(wk2_results[[1]]$Season),
                                       last_game_num = last(wk2_results[[1]]$Game),
                                       last_round = last(wk2_results[[1]]$Round))
  
  
  # Step 3 - get the right teams
  wk3_fixture <- wk3_teams %>%
    map(~wk3_fixture %>%
          mutate(Home.Team = .x$Winner[c(which(.x$Game_Name == "QF1"), which(.x$Game_Name == "QF2"))],
                 Away.Team = .x$Winner[c(which(.x$Game_Name == "SF2"), which(.x$Game_Name == "SF1"))]))
  
  # Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
  wk3_fixture <- wk3_fixture %>%
    map(add_formula_variables)
  
  
  # Step 5 - simulate results
  wk3_results <- simulate_finals(form, wk3_fixture, finals_elos, sim_num)
  } else {
    wk3_results <- finals_results %>%
      filter(Finals_week == 3) %>%
      mutate(Game_Name = get_wk3_names(Rank)) 
      
      wk3_results <- 1:sim_num %>%
        map(~mutate(wk3_results, Sim = .x))
      
      wk4_teams <- wk3_results %>%
        map(~mutate(.x,
                    Winner = ifelse(Win == 1, Home.Team, Away.Team),
                    Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
              select(Season, Finals_week, Game_Name, Winner, Loser, Sim))
  }
  
  
  # Week 4 -----------------------------------------------------------------------
  cli_progress_step("Simulating Fnals Week 4")
  if (finals_week < 4) {
  # Step 1 - get week 2 teams
  
  wk4_teams <- wk3_results %>%
    map2(.y = wk3_teams, 
         ~mutate(.x,
                 Winner = ifelse(Win == 1, Home.Team, Away.Team),
                 Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
           select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
           bind_rows(.y))
  
  # Step 2 - create fixture
  wk4_fixture <- create_finals_fixture(week = 4, 
                                       season = last(wk3_results[[1]]$Season),
                                       last_game_num = last(wk3_results[[1]]$Game),
                                       last_round = last(wk3_results[[1]]$Round))
  
  
  # Step 3 - get the right teams
  wk4_fixture <- wk4_teams %>%
    map(~wk4_fixture %>%
          mutate(Home.Team = .x$Winner[c(which(.x$Game_Name == "PF1"))],
                 Away.Team = .x$Winner[c(which(.x$Game_Name == "PF2"))]))
  
  # Step 4 - add variables for sims NOTE - ASSUMING NEUTRAL VENUE
  wk4_fixture <- wk4_fixture %>%
    map(add_formula_variables)
  
  
  # Step 5 - simulate results
  wk4_results <- simulate_finals(form, wk4_fixture, finals_elos, sim_num)
  } else{
    wk4_results <- finals_results %>%
      filter(Finals_week == 4) %>%
      mutate(Game_Name = "GF") 
      
      wk4_results <- 1:sim_num %>%
        map(~mutate(wk4_results, Sim = .x))
  }
  # Combine and sunmmarise -------------------------------------------------------
  cli_progress_step("Combining finals sims data")
  final_teams <- wk4_results %>%
    map2(.y = wk4_teams, 
         ~mutate(.x,
                 Winner = ifelse(Win == 1, Home.Team, Away.Team),
                 Loser = ifelse(Win == 0, Home.Team, Away.Team)) %>%
           select(Season, Finals_week, Game_Name, Winner, Loser, Sim) %>%
           bind_rows(.y))
  
  final_results <- final_teams %>%
    map(~.x %>%
          pivot_longer(c(Winner, Loser),
                       names_to = "Result",
                       values_to = "Team") %>%
          group_by(Team) %>%
          mutate(max_week = max(Finals_week)))
  
  final_game <- final_results %>%
    map(~.x %>%
          filter(max_week == Finals_week) %>%
          mutate(Game = str_remove(Game_Name, "[0-9]"),
                 Game = ifelse(Game == "GF" & Result == "Winner", "Premier", Game)) %>%
          select(Season, Team, Game, Finals_week, Sim))
  
  finals_dat <- list(final_teams = final_teams,
       final_results = final_results,
       final_game = final_game)

  return(finals_dat)
}


combine_finals_sims <- function(final_game,
                                sim_data_summary, 
                                results, 
                                elo.data,
                                sim_num = 1,
                                ladder = NULL,
                                home_and_away_complete = FALSE) {
  
  cli_progress_step("Combining Finals Sims")
  
  final_summary_long <- purrr::reduce(final_game, bind_rows)
  final_summary_wide <- final_summary_long %>%
    group_by(Season, Team) %>%
    summarise(
      win_league = sum(Game == "Premier"),
      make_gf = sum(Game == "GF") + win_league,
      make_prelim = sum(Game == "PF") + make_gf,
      make_semis = sum(Game == "SF") + make_prelim,
      make_finals = n()
    ) %>%
    mutate_if(is.numeric, ~./sim_num)
  
  final_summary_wide[is.na(final_summary_wide)] <- 0
  
  if(home_and_away_complete) {
    final_ladder <- ladder %>%
      mutate(Margin = pointsFor - pointsAgainst) %>%
      rename(Rank = position,
             Team = team.name,
             Season = season,
             Round = round_number,
             Wins = thisSeasonRecord.winLossRecord.wins,
             Perc = thisSeasonRecord.percentage) %>%
      select(Rank, Team, Season, Round, Margin, Wins, Perc) %>%
      mutate(Top.8 = as.numeric(Rank <= 8),
             Top.4 = as.numeric(Rank <= 4),
             Top.2 = as.numeric(Rank <= 2),
             Top.1 = as.numeric(Rank == 1))

  } else {
    final_ladder <- sim_data_summary %>%
      filter(Season == max(final_summary_wide$Season)) %>%
      filter(Round == max(Round))
  }
  
  last_completed_round <- last(results$Round)
  sims_combined <- final_ladder %>%
    left_join(final_summary_wide, by = c("Team", "Season")) %>%
    mutate(Round = last_completed_round)
  
  # Add elo
  elos <- elo.data %>% 
    final.elos() %>% 
    as.data.frame() %>%
    rownames_to_column("Team")
  elos$elo <- elos$.
  elos <- elos %>%
    select(Team, elo)
  
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
    rename(Team = team.name,
           Season = season,
           Wins = thisSeasonRecord.winLossRecord.wins,
           Losses = thisSeasonRecord.winLossRecord.losses,
           Draws = thisSeasonRecord.winLossRecord.draws) %>%
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
  
  aflm_finals_sims <- list(sims_combined = sims_combined,
                           win_loss = win_loss)
  
}

