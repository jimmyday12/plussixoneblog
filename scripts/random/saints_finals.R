library(tidyverse)
dat <- read_rds(here::here("data_files", "raw-data", "AFLM_sims.rds"))


get_oppo <- function(rank){
  case_when(rank == 1 ~ 4,
            rank == 2 ~ 3,
            rank == 3 ~ 2,
            rank == 4 ~ 1,
            rank == 5 ~ 8,
            rank == 6 ~ 7,
            rank == 7 ~ 6,
            rank == 8 ~ 5,
            TRUE ~ 0)
}

dat_stk <- dat$sim_data_all %>%
  mutate(stk_finals = Top.8 & Team == "St Kilda",
         stk_rank = ifelse(Team == "St Kilda", Rank, NA)) %>%
  group_by(Sim) %>%
  mutate(stk_finals = any(stk_finals),
         stk_rank = max(stk_rank, na.rm = TRUE)) %>%
  arrange(desc(Team)) %>%
  filter(stk_finals)

dat_stk <- dat_stk %>%
  ungroup() %>%
  mutate(oppo_rank = get_oppo(stk_rank)) %>%
  mutate(oppo = ifelse(oppo_rank == Rank, Team, NA)) %>%
  filter(!is.na(oppo))

dat_stk %>%
  group_by(stk_rank, oppo) %>%
  tally() %>%
  arrange(desc(n)) %>%
  mutate(perc = n/9096*100) %>%
  select(-n)

dat_stk %>%
  group_by(oppo) %>%
  tally() %>%
  arrange(desc(n)) %>%
  mutate(perc = n/9096*100) %>%
  select(-n)


  