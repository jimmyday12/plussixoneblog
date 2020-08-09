# Helper functions
# 



# Fix Venues
venue_fix <- function(x){
  case_when(
    x == "MCG" ~ "M.C.G.",
    x == "SCG" ~ "S.C.G.",
    x == "Etihad Stadium" ~ "Docklands",
    x == "Marvel Stadium" ~ "Docklands",
    x == "Blundstone Arena" ~ "Bellerive Oval",
    x == "GMHBA Stadium" ~ "Kardinia Park",
    x == "Spotless Stadium" ~ "Blacktown",
    x == "Showground Stadium" ~ "Blacktown",
    x == "UTAS Stadium" ~ "York Park",
    x == "Mars Stadium" ~ "Eureka Stadium",
    x == "Adelaide Arena at Jiangwan Stadium" ~ "Jiangwan Stadium",
    x == "TIO Traegar Park" ~ "Traeger Park",
    x == "Metricon Stadium" ~ "Carrara",
    x == " Metricon Stadium" ~ "Carrara",
    x == "TIO Stadium" ~ "Marrara Oval",
    x == "Optus Stadium" ~ "Perth Stadium",
    x == "Canberra Oval" ~ "Manuka Oval",
    x == "UNSW Canberra Oval" ~ "Manuka Oval",
    TRUE ~ as.character(x)
  )
}







