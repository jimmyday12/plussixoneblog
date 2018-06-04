
library(pacman)
pacman::p_load(XML, ggplot2, reshape2, quantreg, plyr, data.table)

metaURL <-"http://www.fifa.com/worldranking/rankingtable"
metaParse <- htmlParse(metaURL)

########################################

getRankingTableURL <- function(
  gender="m",
  rank=238, #238 is most recent as of May2014 - counts down to older
  confederation=0, #0 gets all teams
  page=1 #counts up from one for more and more teams
){
  base="http://www.fifa.com/worldranking/rankingtable"
  tail="_ranking_table.html"
  return(paste0(base,
                "/gender=",gender,
                "/rank=",rank,
                "/confederation=",confederation,
                "/page=",page,
                "/",
                tail)
  ) 
}
getRankingTableURL(confederation=23913)

#######################################
### Get the nodes I want via XPATH query
#
start_rank = 286 #may want to replace with scraped number
end_rank = 57 #57 corresponds to Jan99, when point method was revised
conf_ids = c(23913,23914,23915,23916,25998,27275)


pointDF <- data.frame()
for(rank in start_rank:end_rank){
  for(confi in conf_ids){
    tableURL <- getRankingTableURL(rank=rank,confederation=confi)
    tableParse <- htmlParse(tableURL)
    
    #Get date of the table
    dtString <- xmlValue(getNodeSet(tableParse,"//div[@class='rnkwrap rnkdate']")[[1]][['div']])
    dt <- as.Date(paste0("1 ",gsub("^\\s*","",dtString)),"%d %B %Y")
    
    #Get table data
    tableList <- getNodeSet(tableParse,"//table[@id='tbl_rankingTable']")
    tableM <-  t(
      sapply(
        tableList[[1]][['tbody']]['tr'],
        function(x){
          tdList <- x['td']
          c(
            #rank=xmlValue(tdList[[2]]),
            name=gsub("^\\s*","",xmlValue(tdList[[4]])),
            #abr=gsub("'","",strsplit(xmlGetAttr(x,"onclick"),",")[[1]][2]),
            points=gsub("^\\s*","",xmlValue(tdList[[5]]))
          )
        }
      )
    )
    
    #Turn table matrix in to data.frame
    pointDF <- rbind(pointDF,data.frame(date=dt,confid=confi,tableM, stringsAsFactors=F))
  }
}


write.csv(pointDF,"fifa_rank_history.csv",row.names=F)
