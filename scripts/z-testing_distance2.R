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
  map_dfr(select, Ground:Capacity) 

names(grounds) <- make.names(names(grounds))

grounds <- grounds %>%
  mutate(State = ifelse(is.na(State), State.territory, State),
         in.world.cities = City %in% maps::world.cities$name)

capitals <- data.frame(
  State = c("Victoria", "Tasmania", "New South Wales", "Queensland", "South Australia", "Western Australia", "Australian Capital Territory", "Northern Territory"),
  City = c("Melbourne", "Hobart", "Sydney", "Brisbane", "Adelaide", "Perth", "Canberra", "Darwin")
)


# Step 2: Write datatable with team and home city

# Step 3: use imap from above to get distance for every combination

# Step 4: calculate distance

