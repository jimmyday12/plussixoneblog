---
title: Round 21 Ratings and Simulations - Hawks back to the pack
author: jamesday87
date: '2016-08-10'
categories:
  - AFL
  - Simulation
slug: round-21-simulations
---

With a big upset loss on the weekend, the Hawks is the biggest loser from the weekend results. They have dropped back into the pack of clustered teams below our clear leaders and now face a possibility of losing top spot before the season is out.

# New ratings

In fact - despite having a relatively good week for head to head tipping, our [ELO model](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/) has shown some considerable adjustment to the rankings this week. This relates to some big upsets and misses in the margin, [which we ultimately use to reassess our team ratings](http://plussixoneblog.com/2016/05/12/simulating-the-season/). We've seen 12 teams change places on our table (although only 5 of our top 8). The biggest changes come out of the Hawthorn/Melbourne and St Kilda/Carlton games.

In our top 8 race, Sydney and Adelaide have consolidated their grip as the clearly the two best rated teams. They have both opened up their lead on the remainder of the top 9 ranked teams apart from West Coast. In fact, Sydney would now start favourite against any team other than Adelaide regardless of the home ground advantage (HGA) boost ([nominally set at 35 rating points](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/)). Adelaide is approaching that status, sitting 30 rating points above the next best side in Geelong.

    <img src="http://plussixoneblog.com/img/2016/08/unnamed-chunk-1-1.png" alt="plot of chunk unnamed-chunk-1" />

In the race for the worst team for the season, the Bombers have jumped above the Lions. The Lions have in fact edged close dropping below 1300 mark, which is almost 8 goals worse than an average team. In fact, only 12 teams in history have dropped below that ELO rating within a season. I promise I'll write a post before the season is out about these two teams and where they sit in historical seasons but depending on how we measure 'worst' seasons by a team, they are on track to both finish within the worst 20.

# Simulations

Onto our simulations, and I've finally got around to adding in some finals sims!

Firstly to our finals race, and we know have 5 teams that have clinched a finals spot. Two more teams (Bulldogs and WCE) will likely add to that list with a win this week, with only North Melbourne any realistic chance of dropping out. St Kilda improved their chances to jumping into the 8 to 17%, to be the most likely. They need to make up [2 games and percentage from the remaining 3 games](http://www.heraldsun.com.au/sport/afl/teams/st-kilda/st-kilda-clings-to-unlikely-afl-finals-dream/news-story/c02687a3f52d2cf5af9021b79e1c3e65) to do that, but based on the relative strengths of the teams involved, we'd expect it to occur almost 1 in 5 times, so the excitement continues!
![simTableR21](http://plussixoneblog.com/img/2016/08/simTableR21-2.png)[
](http://plussixoneblog.com/img/2016/08/simTableR21.png)The top 4 race remains likely to come from 5 teams. The Hawks unexpected loss on the weekend sees their chances drop considerably but still remain at around 3 in every 4 sims. We actually give Geelong and Sydney more chances of making it, despite sitting 1 game behind the Hawks.

We see a similar distribution in top 2 chances, however interestingly  the Hawks are still our favourite to clinch the Minor Premiership, although their chances dropped from 67% down to 29% this week.

##### Finals Sims!

Our first set of finals simulations and we are again favouring the same 5 teams as our most likely premiers. Our predictions for the Prelim are very similar to our top 4 chances, with only GWS having less than a 64% chance of making it that far. In terms of the grand final, Sydney are our favourites to make it, reaching the final weekend in almost half of all simulations. They also win that match in about 1/4 of simulations, making them our premiership favourites.

It will be interesting to see how these finals simulations progress - as Hawks showed last week, an unexpected loss could change the picture dramatically!

![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/img/2016/08/unnamed-chunk-2-1-2.png)
