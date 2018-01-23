---
title: Round 20 Prediction - shuffling the pieces
author: jamesday87
date: '2016-08-04'
categories:
  - AFL
  - Predictions
slug: round-20-prediction-shuffling-pieces
---

Leading into the final month of the season, [match simulations suggesting that the top 8 is basically set](http://plussixoneblog.com/2016/08/01/round-20-elo-simulations/). In fact, the top 8 hasn't changed since before Round 7. As we wrote about at the time, [that isn't all that surprising](http://plussixoneblog.com/2016/05/05/the-round-7-rule/). Given that - we'd perhaps expect that the remaining games aren't all that important, [as measured by our match importance metric](http://plussixoneblog.com/2016/06/16/beyond-the-8-point-game-estimating-match-importance-in-the-afl/). However, since very little separates teams in our top 8, matches involving those teams are particular important this week!

### Round Predictions

![round20](http://plussixoneblog.com/img/2016/08/round20-1024x155.png)

Unlike [last week](http://plussixoneblog.com/2016/07/29/round-prediction/) - our [ELO model](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/) sees some harder to predict matches this week. There are few matchups between teams [close on our ELO rankings](http://plussixoneblog.com/2016/08/01/round-20-elo-simulations/). While our two closest games have very little 'importance' in terms of the season, one could argue that each team has a fair bit to play for. Richmond v Collingwood on Friday night shapes as a big match for a Tigers team under siege, while Carlton v St Kilda is probably the key match between two up and coming teams on the tail end of a rebuild. As per our norm though - I'll discuss some of the more important matches below.

### Match Importance

![plot of chunk unnamed-chunk-5](http://plussixoneblog.com/img/2016/08/unnamed-chunk-5-1-1.png)

###### **Sydney v Port Adelaide, Sat 1:45pm, SGC.[
](http://plussixoneblog.com/img/2016/07/simTableR19-1.png)**

Port Adelaide continues to keep themselves in with an (albeit) small chance of making the top 8. This match looks like being their last chance to remain in with a realistic chance. A win sees their probability jump to ~20%, while a loss sees it drop down to <2%. Given Sydney is one of 4 of our best rated teams vying for 3 spots in the top 4, losing this match puts a big dent in their hopes of top 4. We see a 40 percentage point swing between a win and a loss. Given the relative strength of Sydney and their home ground advantage (HGA), our ELO model is giving Sydney a 63% chance of winning this one. _**Sydney by 21 points. **_

**Western Bulldogs v North Melbourne, Sat 7:25pm, Etihad.**

Both the Bulldogs and Kangaroos have been struggling of recent weeks for varying reasons. In this time, they've dropped to 9th and 8th respectively in our ELO ratings. The Bulldogs early season work does see them more than likely to hold onto 8th spot but if they want to make a run for top 4, this match is important, showing a 35 percentage point swing based on a win or a loss. For North, they're biggest risk is dropping out of the 8 and a loss here sees those chances jump to 60% probability of missing! The Bulldogs, despite a slight rating deficit, gets the edge here with HGA, with ELO model placing them at a 53% chance in a hard one to predict. _**Bulldogs by 5 points. **_

**Weighted Importance**

The remaining matches - while seemingly important - highlight the need for me to weight these importance ratings based on the probability of the win or loss actually occurring. As an example this weekend - a win or a loss sees their top 4 hopes change by almost 50 percentage points. The actually probability of the Lions upsetting the Crows however from our ELO model is only 12%. I'm not sure I'll have time before the season to fix this as I want to get my finals simulations completed but it is something to note!
