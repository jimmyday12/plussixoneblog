library(gmapsdistance)
APIkey <- "AIzaSyBMU19-03Jz0caEfGLa-UtgbUanfdk0J0M"
set.api.key(APIkey)
results = gmapsdistance(origin = c("Washington+DC", "New+York+NY"), 
                                                 destination = c("Los+Angeles+CA", "Austin+TX"), 
                                                 mode = "driving", 
                                                 avoid = "tolls",
                                                 key=APIkey)

gmapsdistance(origin = "Washington+DC", 
              destination = "New+York+City+NY", 
              mode = "driving")
install.packages("ggmap")
library(ggmap)
mapdist('Melbourne', 'Perth', mode = 'driving')

mapdist("MCG", "Richmond, Vic", mode = 'driving')$km
mapdist_dist <- function(from, to){
  mapdist(from, to, mode = "driving")$km
}

fixture <- fixture %>%
  mutate(Home.Dist = mapdist_dist(Home.Team, Venue))



## New test ------------------------
library(fitzRoy)
library(ggmap)
library(tidyverse)

fixture <- get_fixture()


# create vector of place names
places_names <- data.frame(
  Venue = unique(fixture$Venue),
  stringsAsFactors = FALSE
)

# geocode place names
places <- places_names %>%
  mutate_geocode(Venue, source="google", sensor = TRUE)

places_lat <- places$lat
places_lon <- places$lon

# create a data frame to store all variables
places_df <- data.frame(names = places_names,
                        lat = places_lat,
                        lon = places_lon)

# calculate geodesic distance with gdist() from Imap package

# load Imap
library(Imap)

# create an empty list
dist_list <- list()

# iterate through data frame placing calculated distance next to place place names
for (i in 1:nrow(places_df)) {
  
  dist_list[[i]] <- gdist(lon.1 = places_df$lon[i], 
                          lat.1 = places_df$lat[i], 
                          lon.2 = places_df$lon, 
                          lat.2 = places_df$lat, 
                          units="miles")
  
}

# view results as list
dist_list

# unlist results and convert to a "named" matrix format
dist_mat <- sapply(dist_list, unlist)

colnames(dist_mat) <- places_names

rownames(dist_mat) <- places_names

# view resu


## Another try

