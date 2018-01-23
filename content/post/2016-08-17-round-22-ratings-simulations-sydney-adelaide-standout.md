---
title: Round 22 Ratings and Simulations - Sydney and Adelaide standout
author: jamesday87
date: '2016-08-17'
categories:
  - AFL
slug: round-22-ratings-simulations-sydney-adelaide-standout
---

As we enter our final 2 rounds of the season, we continue to see two standout teams. North has also failed to again lock up a finals position - leaving the door ajar with their loss to the Hawks

<!-- more -->

## New Ratings

The big wins by Sydney and Adelaide saw them extend their lead a the top of the [ELO ratings ](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/)table. They both now have a pretty big lead over the third ranked team in Hawthorn (who leapfrogged Geelong). In fact, both Sydney and the Crows would now be favourite against every other team regardless of venue. The chasing pack is quite difficult to separate, with West Coast probably joining a group of 3 others as our '2nd tier' teams.

![plot of chunk ratingplot](http://plussixoneblog.com/img/2016/08/ratingplot-1.png)

Melbourne's big win on the weekend saw them gain our most ratings points for the weekend. While they didn't change positions on the rankings ladder, this big gain did see them break through the 'average' team rating of 1500 for the first time since Round 14 in 2011. This round was in fact the last time Melbourne has been inside the top 8[ref]outside of round 1[/ref]. As seen below, in that year they only spent 4 rounds over the 1500 point mark, showing just how bad they have been. At least the path is looking positive!

![plot of chunk unnamed-chunk-1](http://plussixoneblog.com/img/2016/08/unnamed-chunk-1-1-1.png)

# Simulation

Our simulations this week show that the Bulldogs have now joined our guaranteed finals positions, with GWS and WCE basically joining them. Norths big loss saw them drop rating points and keep the door ajar for both Saints and Melbourne. I should note however that this week has revealed a slight problem with my ratings - because I only get a predicted margin, my method for resolving 'ties' only takes into account the 'average margin' rather than 'percentage', as the true ladder does. This means that my model is giving the Saints a rather inflated chance of making it into the top 8, despite only being able to finish equal on points with North, and being almost 20 percentage points behind them. It's now added to the ever growing to-do list!

![simTableR22](http://plussixoneblog.com/img/2016/08/simTableR22-1.png)

The makeup of our top 4 also got a little clearer this week. With GWS and Adelaide both losing, our model is pretty confident in Hawthorn, Sydney and Geelong staying there for now. The fight appears to be on for that 4th spot, likely between the Crows and the Bulldogs. The Hawks bouncing back did also see their top 2 and minor premier chances slightly improve.

Our finals simulations are again predicting that our top 4 rated teams are most likely to make it through to the Prelim weekend. The top two rated teams in Sydney and Adelaide are our most likely premiers, while none of our other teams win the premiership in more than 1 in 10 simulations. [
](http://plussixoneblog.com/img/2016/08/simTableR22-1.png)

![plot of chunk simulateplot](http://plussixoneblog.com/img/2016/08/simulateplot-1.png)
