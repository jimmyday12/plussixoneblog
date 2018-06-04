library(pacman)
pacman::p_load(tidyverse, lubridate, rvest, tictoc)
tic()

# Create function to generate URL
get_ranking_table_URL <- function(rank, confederation, gender = "m", page = 1){
  base <- "http://www.fifa.com/worldranking/rankingtable"
  tail <- "_ranking_table.html"
  return(paste0(base,
                "/gender=", gender,
                "/rank=", rank,
                "/confederation=", confederation,
                "/page=", page,
                "/",
                tail)
  ) 
}

# Generate URLS ----------------------------------------------------------------
# Specify parameters
start_rank = 286 # the last update (as of Jun 5th, 2018)
end_rank = 57 # corresponds to Jan99, when point method was revised
conf_ids = c(23913, 23914, 23915, 23916, 25998, 27275)

rank <- rep(start_rank:end_rank, each = length(conf_ids))
conf_vec <- rep(conf_ids, times = length(start_rank:end_rank))

urls <- rank %>%
  map2_chr(conf_vec, ~ get_ranking_table_URL(rank = .x, confederation = .y))

# Read each URL and download the HTML
# Found this code to do a progress bar - kind of ugly but nice to know where we are at
pb <- progress_estimated(length(urls))
htmls <- urls %>%
  map(~{
    pb$tick()$print()
    read_html(.x)
    })

# Read date
dates <- htmls %>% 
  map(~html_nodes(.x, ".lb")) %>%
  map(html_text) %>%
  map_chr(~str_remove(.x, "Last Updated ")) %>%
  map(dmy) 

# Read Tables
tables <- htmls %>% 
  map(~html_nodes(.x, "#tbl_rankingTable")) %>%
  map(html_table) %>%
  map(as.data.frame)

# Add date, conf id and make into one dataframe
dat <- tables %>%
  map2(dates, ~ .x %>% mutate(Date = .y)) %>%
  map2(conf_vec, ~ .x %>% mutate(Conference_id = .y)) %>%
  reduce(bind_rows) %>%
  select(Date, Team, Pts, Conference_id) %>%
  arrange(Date, desc(Pts))

# Write out
write_csv(dat, here::here("projects", "world-cup-2018", "fifa_rank_history.csv"))
toc()