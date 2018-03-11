simSeason <- function(fixture, 
                      team_elo = data.frame(),
                      simulation = 1){
  
  message("Simulating season", simulation)
  simulated_results <- tibble()
  
    # Get data
    for (i in seq_along(fixture$Game)){
      
      # get game details
      game <- fixture[i,]
      
      # Find elo diff
      game$home_elo <- team_elo$ELO[(team_elo$Team == game$Home)]
      game$away_elo <- team_elo$ELO[(team_elo$Team == game$Away)]
      elo_diff <- game$home_elo - game$away_elo + HGA
      
      # Find expected outcome based on elo
      exp_margin <- find_expected_margin(elo_diff, M)
      
      # sample from rnorm of mean marg and historical SD
      game$margin <- round(rnorm(1, exp_margin, sd = 41))

      team_elo$ELO[(team_elo$Team == game$Home)] <- update_elo(game$margin, home_elo, away_elo)
      team_elo$ELO[(team_elo$Team == game$Away)] <- update_elo(game$margin, home_elo, away_elo, returns = "away")
      
      simulated_results <- simulated_results %>%
        bind_rows(game)
    }
  
  simulated_results <- simulated_results %>%
    mutate(sim_number = simulation)
  
  return(simulated_results)
}   

library(tidy)

fixture <- dat.2017 %>%
  filter(RoundNum >= 5) %>%
  select(Game:Away)

current_elo <- x %>%
  group_by(Team) %>% 
  filter(RoundNum < 5) %>%
  filter(TeamSeasGame == max(TeamSeasGame)) %>%
  select(Team, ELO_post) %>%
  rename(ELO = ELO_post)

library(purrr)
sims <- 1:5
simdf <- map_df(sims, ~ simSeason(fixture, team_elo = current_elo, simulation = .x))







    sim <- group_by(dat,Team) %>% 
      summarise(Wins = sum(as.logical(Result)),
                Margin = sum(Margin),
                Simulation = j,
                ELO_pre = last(ELO_pre)
      )
    
    # Get result of first game
    firstGame <- group_by(dat,Team) %>%
      filter(Round == strtRnd) %>%
      mutate(firstG = Result) %>%
      select(Team, firstG)
    
    
    sim <- left_join(sim,firstGame, by = "Team")
    
    simDat <- rbind(simDat,sim)
    chnk <- 100
    if (j == 1 | j %% chnk == 1)
    {print(paste("Simulating Season",j, "to", j+chnk-1))}
  }
  # Calculate rank
  rnd <- paste("R",strtRnd-1,sep="")
  prevrnd <- paste("R",strtRnd-2,sep="")
  
  # Load historical data
  load("./Data/AFL_ELO_Hist.rda")
  
  result_function <- function(x){
    if (x > 0){
      return(1.0)
    } else if (x < 0){
      return(0.0)
    } else {
      return(0.5)
    }
  }
  
  actWins <- datNew %>%
    group_by(row_number()) %>%
    filter(Season==season) %>%
    mutate(result_num = result_function(Margin)) %>%
    group_by(Team) %>%
    summarise(Wins = sum(result_num),
              Margin = sum(Margin))
  
  # Find summaries
  simDatAll<-left_join(simDat, actWins, by="Team") %>% 
    group_by(Team, Simulation) %>%
    mutate(Wins = sum(Wins.x, Wins.y, na.rm = T),
           Margin = sum(Margin.x, Margin.y, na.rm = T)) %>%
    select(Simulation, Team, Wins, Margin, ELO_pre, firstG)
  
  # Find ranks
  simDatRanks <- simDatAll %>% 
    group_by(Simulation) %>% 
    arrange(desc(Margin))%>%
    mutate(rank=row_number(-Wins),
           top.8=ifelse(rank<9,1,0),
           top.4=ifelse(rank<5,1,0),
           top.2=ifelse(rank<3,1,0),
           top.1=ifelse(rank<2,1,0))
  
  # Save this for finals sims
  save(simDatRanks,file = 
         paste("./Data/Simulations/", season, "_",strtRnd,"to", 
               endRnd, "_simDatRanks.rda",sep=""))
  
  # Get percentage of finishing positions
  final <- group_by(simDatRanks,Team) %>%
    summarise(WinMean = mean(as.integer(Wins)),
              MarginMean=mean(Margin),
              WinSD = sd(as.integer(Wins)),
              MarginSD=sd(Margin),
              top.8=sum(top.8)/n(),
              top.4=sum(top.4)/n(),
              top.2=sum(top.2)/n(),
              top.1=sum(top.1)/n(),
              seasons = n()) %>%
    arrange(desc(WinMean))
  
  
  
  
  # Get elo
  elo <- datNew %>%
    filter(Season==season & RoundNum<=strtRnd) %>%
    group_by(Team) %>%
    filter(TeamSeasGame == max(TeamSeasGame)) %>%
    mutate(ELO=ELO_post) %>%
    select(Team,ELO)
  
  # Get ELO change
  # First find this round
  rndTm <- datNew %>%
    filter(RoundNum == strtRnd-1 & Season == season) %>%
    select(Team)
  
  eloChange <- datNew %>%
    filter(RoundNum<=strtRnd-1 & Season==season) %>%
    group_by(Team) %>%
    filter(TeamSeasGame==max(TeamSeasGame)) %>%
    select(Team,ELO_post,ELO_pre) %>%
    ungroup() %>%
    arrange(desc(ELO_post)) %>%
    mutate(thisRound = Team %in% rndTm$Team) %>%
    mutate(ELODiff = ifelse(thisRound,ELO_post-ELO_pre,NA),
           ELO = ELO_post) %>%
    select(Team,ELO,ELODiff)
  
  
  ## Combine with Final
  simSeas <- left_join(final,eloChange, by = "Team") %>%
    mutate(Wins=WinMean) %>%
    arrange(desc(Wins)) %>%
    select(Team,ELO,ELODiff,Wins,MarginMean,top.8,top.4,top.2,top.1) %>%
    mutate(Rank = min_rank(-Wins))
  
  simSeas$Team <- factor(simSeas$Team, levels = simSeas$Team[order(desc(simSeas$Wins))])
  simDat$Team <- factor(simDat$Team,levels=simSeas$Team[order(desc(simSeas$Wins))])
  simDatAll$Team <- factor(simDatAll$Team,levels=simSeas$Team[order(desc(simSeas$Wins))])
  
  # Save this data
  save(simDat,file=paste("./Data/Simulations/", season, "_",strtRnd,"to", endRnd, "_simDat.rda",sep=""))
  save(simSeas,file=paste("./Data/Simulations/", season, "_",strtRnd,"to", endRnd, "_simSummary.rda",sep=""))
  save(simDatAll,file=paste("./Data/Simulations/", season, "_",strtRnd,"to", endRnd, "_simDatAll.rda",sep=""))
  write.csv(simSeas,file=paste("./Data/Simulations/", season, "_",strtRnd,"to", endRnd, "_simSummary.csv",sep=""))
  
  return(simSeas)
}
