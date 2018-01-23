---
title: Round 23 Ratings and Simulations - Set in stone
author: jamesday87
date: '2016-08-24'
categories:
  - AFL
slug: round-23-ratings-simulations-set-stone
---

As the Dee's finals hopes melted away like the snow their fans had been enjoying all winter, our final 8 became set in stone. Barring North losing by a record margin and St Kilda winning by one, we won't be seeing any changes in our finals teams.

<!-- more -->

[As we wrote about earlier in the year](http://plussixoneblog.com/2016/05/05/the-round-7-rule/) - typically after around round 7 we generally see less than 2 teams move into the 8. This year however, our finals teams have actually been set since round 6, which is particularly early. I failed to discuss in the previous piece where our ladder is generally 'set in stone', so I've explored that in the below plot. This shows the point in the season where we don't see any teams move into the top 8. I chose 1925 as this was the point in which our league expanded to 12 teams. I also decided to use the 'top 8' as my cut off rather than 'finals'.

![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/img/2016/08/unnamed-chunk-2-1-8.png)

We can see that generally this occurs around 4-6 weeks out from finals and is pretty rare to occur so early as it did this year. In fact, the table below shows just how rare - it has only occurred in Round 6 or earlier on 8 occasions! The most recent of those years was in 1971. In fact, in all of those years, we didn't actually have a final 8. We certainly didn't have 18 teams so this year has been particularly rare!

```r
##    Year Round
##   (int) (dbl)
## 1  1932     4
## 2  1933     3
## 3  1938     4
## 4  1953     4
## 5  1956     4
## 6  1965     4
## 7  1969     4
## 8  1971     6
```

## New ratings

Our biggest move in our [ELO ratings](http://plussixoneblog.com/elo-rating-system/) this week probably came from GWS who have pushed themselves up to 3rd spot. They now sit slightly clear of the 'also ran' group of Geelong, Hawthorn and West Coast in a congested chase pack. They are still sit significantly behind Sydney and Adelaide, although those two teams did get adjusted down in our ratings this week, albeit very slightly.

![plot of chunk ratingplot](http://plussixoneblog.com/img/2016/08/ratingplot-1-1.png)

# Simulation

Moving on to the final simulations and we can see that probably the big loser from the weekend (apart from Melbourne and St Kilda) was Hawthorn. Their top 4 chances dropped from >87% down to less than 2 in 3 simulations. They are almost equal with GWS as a chance for that top 4 and it is hard seeing them hold in if they lose to the Pies this week.

![simTableR23](http://plussixoneblog.com/img/2016/08/simTableR23.png)

Their drop in form and potential miss of the top 4 also sees their premiership credentials fall in our finals simulations. Again - they are roughly equal with GWS to nab a prelim spot, most likely against Sydney or Adelaide. Those two teams are now emerging as our clear premiership favourites (lagging a little behind them emerging as our top ranked ELO rating teams a few weeks ago). We can probably put a line through North, West Coast and the Bulldogs at this stage.

![plot of chunk simulateplot](http://plussixoneblog.com/img/2016/08/simulateplot-1-1.png)[
](http://plussixoneblog.com/img/2016/08/simTableR23.png)
