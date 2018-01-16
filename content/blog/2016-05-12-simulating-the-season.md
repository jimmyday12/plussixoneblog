---
title: Simulating the season
author: jamesday87
date: '2016-05-12'
categories:
  - AFL
  - Simulation
slug: simulating-the-season
---

As I've promised for a few weeks, my [ELO rating system](http://plussixoneblog.com/elo-rating-system/) allows me to simulate the season from points in time to assess the chances of various teams finishing positions, based on information we have gathered during the start of the season.

Below, I've taken each teams current ELO rating, with their current record, and simulated the season 20000 times. For each match, I use the expected result estimated from the ELO difference between the two teams to draw from a probability distribution around that expected result[ref] I believe this is formally known as [Monte Carlo Simulation](https://en.wikipedia.org/wiki/Monte_Carlo_method)[/ref]. These simulations are "hot" in the sense that after each simulated match, I update the ELO rankings. I'll probably write a seperate post [ref] with my ELO system explainer[/ref] on that, but here is [FiveThirtyEight's](http://fivethirtyeight.com/datalab/an-nfl-team-will-probably-win-14-games-we-just-dont-know-which-team/) reasoning on why this is a good idea, which is good enough for me. The nice part about this methodology is that it takes into account a teams draw, their current rating and their current record.

I'm hoping to potentially turn this into an interactive table [ref]anyone with advice? ShinyApps is something I've considered)[/ref]. For now, I'll update each week with a static image.

![finalR7to23_2016C](http://plussixoneblog.com/wp-content/uploads/2016/05/finalR7to23_2016C.gif)

One interesting point is the big drop-off in percentages for finishing in the top 8 between 8th placed West Coast and 9th placed Port. It seems, as I wrote about previously, [that the final 8 is taking shape already this early on. ](http://plussixoneblog.com/2016/05/05/the-round-7-rule/) In fact, this seems quite common amongst those generating rating systems.

<blockquote>

>
> .[@figuringfooty](https://twitter.com/figuringfooty)'s ratings suggest there's a large gap between the teams currently in the 8 & the rest of the comp: <https://t.co/TNQIc3jp3Y>
>
>
— The Arc (@TheArcFooty) [May 10, 2016](https://twitter.com/TheArcFooty/status/729824609139228673)</blockquote>

<blockquote>
[@figuringfooty](https://twitter.com/figuringfooty) [@TheArcFooty](https://twitter.com/TheArcFooty) I see a similar pattern. Big drop-off between 8th and 9th. Should be a fun September! [pic.twitter.com/TrkiD5mpEU](https://t.co/TrkiD5mpEU)

— plusSixOne (@plusSixOneblog) [May 10, 2016](https://twitter.com/plusSixOneblog/status/729843197887680512)
</blockquote>

If the top 8 stays this tight, then we could be in for a super interesting finals series. That's if we can get through the dullness of the top eight being set already.
