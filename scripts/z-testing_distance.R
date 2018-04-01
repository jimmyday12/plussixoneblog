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
