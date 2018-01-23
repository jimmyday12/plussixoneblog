---
title: Round 9 predictions
author: jamesday87
date: '2016-05-20'
categories:
  - AFL
  - Predictions
slug: round-9-predictions
---

Last weekend we again managed 6 correct tips, with an MAE of 33.9, bringing our season total to 52 (72%) with an MAE of 31.8. I'm hoping from here on in, we can maintain greater than 70% tipping and get the MAE under the 30 point mark [ref] I already have some thoughts on improvements of the ELO rating system[/ref]

Onto this weekend, it looks like there are two standout games in the Hawks v Swans and the GWS v WB matchup. All 4 teams in our congested top 8, with the Hawks rated slightly higher, and at home, while the home ground advantage giving the Giants a slight edge over WB.

![round9b](http://plussixoneblog.com/img/2016/05/round9b.gif)

Our ELO ratings again show our clear separation of the Top 8 that we observed last week. This is providing more evidence to the idea that the [Top 8 is already set by this point in the year.](http://plussixoneblog.com/2016/05/05/the-round-7-rule/) It also seems like we have a decent drop-off after about 13th, with not a lot to separate at least the bottom 4 (or maybe 5) teams. I'll continue to monitor these groupings as the year goes on.

It is also interesting that the model still doesn't rate North Melbourne either! Despite this, we give them a very good chance to improve their winning start to the season over Carlton (76% chance) - you can review the analyses of how good that start is [here](http://plussixoneblog.com/2016/05/13/leaping-kangaroos/).

![ELO_preR9](http://plussixoneblog.com/img/2016/05/ELO_preR9.gif)

Simulating the rest of the season shows us again that we are relatively confident that the top 8 is already set, with only Port Adelaide (32%) and Melbourne (24%) making the 8 from outside with any regularity. While our model is is giving Geelong and Hawthorn >70% chance of clinching top 4, it has trouble picking the other teams, with essentially an even spread for the remainder of teams 3rd to 7th.

North Melbourne still sits at a predicted 3rd, despite ranking 8th on our ELO rankings. Those banked early wins are important.
![R8to23](http://plussixoneblog.com/img/2016/05/R8to23.gif)

I've also shown the distribution of wins for each team, with the columns representing groups of 6. Hopefully this shows a little bit that, rather than predicting Geelong to get exactly 16 wins, that is the mean number of wins in our simulations, with a distribution around that number.

![round9to23](http://plussixoneblog.com/img/2016/05/round9to23.gif)
It also, I think, graphically represents the idea that, we don't think we will have two teams on 16 wins, with 6 teams following on 14 wins, but rather that the mean represents the relative confidence we have in that team finishing higher than another team. In fact, if Geelong ends up on 16 wins, it probably won't even finish 1st, given the high distribution of teams other than Geelong it in the region above 16 wins. [I might explore this concept further](http://fivethirtyeight.com/datalab/an-nfl-team-will-probably-win-14-games-we-just-dont-know-which-team/) in a later post but I'll start to include this plot.
