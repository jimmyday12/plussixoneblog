---
title: Final 2016 Season results
author: jamesday87
date: '2016-09-01'
categories:
  - AFL
  - Results
slug: final-2016-season-results
---

With the home and away season over, and the controversial bye weekend, it gives us a nice chance to review the season performance for the inaugural plusSixOne season. Our [ELO model](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/) managed to get through the last round relatively unscathed, with a total of 6 out of 9 tips. We missed on Adelaide's terribly timed loss to West Coast, the Bombers running over the top of Carlton and Freo getting up against a tired Bulldogs. With a few blowout games on the weekend, our mean absolute prediction error (MAPE) was a pretty season 2nd worst of 37.9, suggesting that perhaps paying less attention to the end of season games may be an improvement I could make to the ELO model in future iterations.

<!-- more -->

The brings to end the season with a total of 142 out of 198 (71.7%) and a MAPE of 29.3. That has allowed me to scrape within both of the goals I'd set at the start of the season (actually - I started this in round 6) of >70% tipping and <30 MAPE. While I'm happy with those results, there are some pretty obvious things I'll look to improve in the off season. I'll write another in-depth post about that later on but a big example is the parameterisation of the home ground advantage, which is currently constant across all games. More to come on that topic!

![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/wp-content/uploads/2016/09/unnamed-chunk-2-1.png)![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/wp-content/uploads/2016/09/unnamed-chunk-2-2.png)![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/wp-content/uploads/2016/09/unnamed-chunk-2-3.png)

# New ratings

Normally I release the readings and simulations together but since I probably won't do the simulations until next week, I'll put the ratings below for reference. We can see the big effect that Adelaide's poor performance has had on their ratings - dropping back to our pack of chasing teams. This leaves Sydney as our clear top rated team. The Hawks continue their tumble down the ratings ladder - potentially losing touch with that chasing pack, although well ahead of the rest.
![plot of chunk unnamed-chunk-3](http://plussixoneblog.com/wp-content/uploads/2016/09/unnamed-chunk-3-1.png)

Melbourne's foray into 'above average' team hasn't lasted long. [We discussed how long it had been since that happened in a previous post](http://plussixoneblog.com/2016/08/10/round-21-simulations/). Hopefully for Melbourne fans, that wait isn't that long to get back there again!

I've said it before but I promise in the coming weeks to review the Essendon/Lions seasons relative to the worst seasons of all time. Essendon has potentially ruined any records with their last couple of weeks but the Lions have been truely horrible. Watch this space.
