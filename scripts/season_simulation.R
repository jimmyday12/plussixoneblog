simSeason <- function(fixture, 
                      results = data.frame(),
                      current_elo = data.frame(),
                      season = 2017, seasons = 10000){
  library(tidyverse)
  library(purr)
  
  # Script to simulate a season
  #For each row
  # a) take ELO_pre for each to simulate a margin/Result using rnorm
  # b) use that margin to update ELO
  # #After season simulated, calc Total Wins, PointsDiff
  #rm(list = ls()) #remove all items from environment

  # Get first game
  if(is_empty(results)) {
    first_game <- 1
  } else {
    first_game <- max(results$Season.Game)
  }
  
  
  
  
  
  
  
  # Set data frames
  # Want to insert current 2016 data into this, based on Start Rnd. 
  seasDat <- seasDat     
  simDat <- data.frame(Team=character(), Wins=integer(), Margin=numeric(),Simulation=integer(), stringsAsFactors=FALSE) 
  
  # Create progress bar
  pb <- tkProgressBar(title = "progress bar", min = 0,
                      max = seasons, width = 300)
  
  
  # Simulations
  ## Start timer
  ptm <- proc.time()
  for (j in 1:seasons){
    
    # Update progress bar
    
    Sys.sleep(0.1)
    setTkProgressBar(pb, j, label=paste( round(j/seasons*100, 0),
                                         "% done"))
    
    # Get data
    dat <- filter(seasDat,Round>=strtRnd & Round <= endRnd) #reset data to raw season dat
    numGms <- nrow(dat)/2
    for (i in 1:numGms){
      
      gameNum <- dat$Game[i]
      rowHome <- i*2
      rowAway <- (i*2) -1
      
      # Get team names
      HomeTeam <- dat$Team[rowHome]
      AwayTeam <- dat$Team[rowAway]
      
      # Get game number for team
      HomeGame <- dat$TeamSeasGame[rowHome]
      AwayGame <- dat$TeamSeasGame[rowAway]
      
      
      ## Now we can perform calculations
      
      # First find expected outcomes
      eloHome <- dat$ELO_pre[rowHome] # Get ELO home ratings
      eloAway <- dat$ELO_pre[rowAway] # Get ELO away ratings
      eloDiff <- eloHome + HGA - eloAway # Calculate ELO Diff
      
      # Find expected outcome
      expOut <- eloExpOutcome(eloDiff,M)
      
      # Convert expected outcome to expected Margin
      expMarg <- eloExpMarg(eloDiff,M,actualRate)
      expRes <- expMarg > 0 #if margin is greater than zero, Res = True = Win
      
      # sample from rnorm of mean marg and historical SD
      predMargin <- rnorm(1,expMarg,sd=marginSD)
      predRes <- predMargin > 0 #if margin is greater than zero, Res = True = Win
      
      # First normalises actual Outcome between 0 and 1, slightly squashed so that
      # there are diminishing gains at higher levels.
      actOut <- eloActOutcome(predMargin,B=actualRate) 
      
      # find Margin of Victory Multiplier
      MOV <- eloMargOfVic(eloDiff,predMargin)
      
      # Expected outcome is for home team. Away team is the negative of it, since
      # ELO is zero sum
      eloChange <- round((k*MOV*(actOut - expOut)))
      
      # Set the new ELO value
      dat$ELO_post[rowHome] <- eloHome + eloChange
      dat$ELO_post[rowAway] <- eloAway - eloChange
      
      ## Set the predictions
      dat$PredRes[rowHome] <- expRes
      dat$PredRes[rowAway] <- !expRes
      dat$PredMarg[rowHome] <- expMarg
      dat$PredMarg[rowAway] <- -expMarg
      dat$PredOut[rowHome] <- expOut
      dat$PredOut[rowAway] <- 1-expOut
      
      # Set the predictions
      dat$Result[rowHome] <- predRes
      dat$Result[rowAway] <- !predRes
      dat$Margin[rowHome] <- predMargin
      dat$Margin[rowAway] <- -predMargin
      
      ## Set next ELO values
      # home team
      homeInd <- dat$Team == HomeTeam & dat$TeamSeasGame == HomeGame + 1
      dat$ELO_pre[homeInd] <- eloHome + eloChange
      
      # away team
      awayInd <- dat$Team == AwayTeam & dat$TeamSeasGame == AwayGame + 1
      dat$ELO_pre[awayInd] <- eloAway - eloChange
      
      
    }
    
    
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