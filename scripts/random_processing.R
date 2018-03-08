

x <- datNew %>%
  filter(Season == 2017) 

dat.2017 <- x %>%
  select(Game, Date, Season, Round, RoundNum, Venue, Team, TeamStatus) %>% 
  spread(TeamStatus, Team) %>%
  left_join(x %>% filter(TeamStatus == "Home") %>% select(Game, Goals, Behinds, Points, Margin)) %>%
  rename(Home.Goals = Goals,
         Home.Behinds = Behinds,
         Home.Points = Points) %>%
  left_join(x %>% filter(TeamStatus == "Away") %>% select(Game, Goals, Behinds, Points)) %>%
  rename(Away.Goals = Goals,
         Away.Behinds = Behinds,
         Away.Points = Points) %>%
  select(Game:Venue, Home, Away, Margin, everything()) %>%
  mutate(Season.Game = Game - min(x$Game) + 1)

  