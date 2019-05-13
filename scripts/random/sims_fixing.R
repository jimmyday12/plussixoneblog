sims_2018 <- read_rds(here::here("data", "raw-data", "sims_history", "AFLM_sims_2018.rds")) 
sims_2018$sim_data_summary

sims_2019 <- read_rds(here::here("data", "raw-data", "sims_history", "AFLM_sims_2019_r7.rds")) 

sim_data_summary <- sims_2018$sim_data_summary %>%
  bind_rows(sims_2019$sim_data_summary)

sim_data_all <- sims_2018$sim_data_all %>%
  bind_rows(sims_2019$sim_data_all)

aflm_sims <- list(
  sim_data_summary = sim_data_summary,
  sim_data_all = sim_data_all
)

write_rds(aflm_sims, path = here::here("data", "raw-data", "AFLM_sims.rds"), compress = "bz")

