library(pacman)
pacman::p_load(fitzRoy, tidyverse, formattable, 
               ggthemes, elo, here, lubridate, 
               widgetframe, ggridges, DT)
sim_dat_list <- read_rds(here::here("data", "raw-data", "AFLM_sims.rds"))


tms <- c("Richmond","West Coast","Geelong","Adelaide","Hawthorn","Melbourne","Sydney","Port Adelaide")
all.sims <- sim_dat_list$sim_data_all %>%
  mutate(current.tm = Team %in% tms) %>%
  group_by(Sim)

current.top.8 <- all.sims %>%
  filter(Top.8) %>%
  summarise(current.tms = sum(current.tm)) %>%
  filter(current.tms == length(tms))

nrow(current.top.8)/nrow(all.sims) * 100

