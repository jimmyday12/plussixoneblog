#
library(tidyverse)
library(rvest)

# Step 1: Get grounds and city from Wikipedia
wiki <- "https://en.wikipedia.org/wiki/List_of_Australian_Football_League_grounds"

wiki_html <- read_html(wiki)

grounds <- wiki_html %>%
  html_nodes("table") %>%
  html_table(fill = T) %>%
  .[1:3] %>%
  map_dfr(select, Ground, City)

# Step 2: Write datatable with team and home city

# Step 3: use imap from above to get distance for every combination

# Step 4: calculate distance

