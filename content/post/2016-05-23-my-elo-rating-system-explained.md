---
title: My ELO rating system explained
author: jamesday87
date: '2016-05-23'
categories:
  - AFL
slug: my-elo-rating-system-explained
---

I've been wanting to try my hand at building a rating system to predict AFL results for a while. I've decided to begin with a relatively simple ELO rating system. The [ELO rating system](https://en.wikipedia.org/wiki/Elo_rating_system) was originally developed to rank chess players, but more recently has been used for a lot of sports, [including AFL](http://www.matterofstats.com), to assess the relative strengths of teams within a competition.

For a super good explainer on how to build an ELO rating system, I highly recommend the following readings

  * [Building your own rating system](http://www.matterofstats.com/mafl-stats-journal/2013/11/25/a-very-simple-team-ratings-system.html?rq=elo) by Matter of Stats

  * [A very simple team rating system](http://www.matterofstats.com/mafl-stats-journal/2013/11/25/a-very-simple-team-ratings-system.html?rq=elo) by Matter of Stats

  * [SimpElo Team Ratings](http://figuringfooty.com/2015/10/09/the-simpelo-team-ratings/) by FiguringFooty

Also anything by FiveThirtyEight where they discuss their ELO ratings for NFL, Baseball and Basketball is useful reading. I'll attempt to explain my system below but cannot recommend those readings enough!

###### Typical ELO

The nice thing about ELO rating systems is their simplicity. Essentially, our only inputs are the rating of the home team, the rating of the away team and the result. From here, we can assess how the result panned out relative to what we would expect given the relative strengths of each side, and then adjust our rating for each team accordingly. If a team wins by more than expected, we give them a bump in ratings. The system is very objective in this sense and doesn't take into account things like the players within a team, weather, emotional responses to recent events and the myriad of subjective factors that a typical punter might inherently use.

The typical ELO rating system uses the following formula[ref]One aspect of my rating system that does slightly differ from FiveThirtyEight is that teams don't always gain points for a win. Their model uses the simple 1, 0.5 and 0 point system for actual results and so a team that wins can never lose points. In my system, a team needs to win by a greater margin than we expect to gain points. An issue with FiveThirtyEight's system that they discuss is autocorrelation, which means that x. They account for this using a Margin of Victory (MOV) multiplier, which essentially scales the k value based upon the margin of victory, so that it is reduced for blowout wins/losses.

In my haste to develop my system, I thought this would be cool to have in my model and so implemented it. While writing this up, I've realised that it probably isn't needed since my calculation for mapping Margin onto a scale of 0 to 1 already "squashes" bigger results. Interestingly however, including it in there does slightly improve my historical performance of predicting results (68.6% correct tips, MAE of 26.8) versus taking it out (67.0% correct tips, MAE of 27.6) over the entire history of the AFL. For continuity, given I've included it in my predictions so far this season, I'll leave it in but I'll likely revisit it after the season. The equation for including the MOV is below.

$latex MOV = \log (abs(Margin) +1) \times \frac{2.2}{0.001\times eloDiff + 2.2} &bg=f0f0f0$

[/ref]

$latex ELO_{new} = ELO_{old} + k(Result_{actual} - Result_{predicted})&bg=f0f0f0$

The mechanics of this equation are basically, take the teams ELO rating before the match, assess if the result was better or worse than predicted, and then add the scaled difference in the predicted and actual result. My main design decisions now are a) how to define the predicted result, b) how to define the actual result and c) what to set scaling parameter _k_ to.

###### Actual Result

In chess, the actual result is typically a 0 for a loss, 0.5 for a draw and 1 for a win, while the predicted result is the probability of winning, based on the difference in ELO ratings between two opponents. This means that if someone wins in an upset (i.e. against an opponent with a higher rating than them), they get a bigger boost in ratings than someone who wins when they are expected to win. Ratings are also zero sum, so the change in ratings for the winner is the same as the negative change in ratings for the loser.

For an AFL system, we could use a similar simple system like the Chess example above, where we assign a 1 for a win and a 0 for a loss, but I've decided to use the Margin of the match as the indicator of performance. To do this, we need to convert the Margin to a comparable scale to our predicted result (i.e. between 0 and 1). For a good example of how this can be done, I refer you once again to MAFL.

In order to get our Actual Result on a scale of 0 to 1, I need to scale it in some way I could use a simple rescaling along the range of all results in the AFL, however I've decided to get a little more complex by using the following equation. It is essentially the [Generalised Logistic function](https://en.wikipedia.org/wiki/Generalised_logistic_function), with most parameters set to 0 or 1 [ref] For clarity, A = Lower asymptote = 0, K = Upper asmpytote = 1, B = Growth Rate = 0.05, v = 1, Q = 1, C = 1 [/ref]

$latex Result_{actual} = \frac{1}{1 + e(-0.05 * Margin)} &bg=f0f0f0$

The mapping of those results is below. Essentially, my model rewards winning by bigger margins, but with diminishing returns. The difference between a 70 and 80 point win is less than the difference between a 5 and a 15 point win. Again, this isn't based on anything other than some creative license on my behalf based on the shape of the curve and by some sage advice in the previously mentioned Matter of Stats post.

![eloAct](http://plussixoneblog.com/wp-content/uploads/2016/04/eloAct.gif)

###### Predicted Result

My predicted rating system is below. This is taken from [FiveThirtyEight's NFL model](http://fivethirtyeight.com/datalab/introducing-nfl-elo-ratings/), which is similar to [traditional ELO models](http://www.eloratings.net/system.html) used in chess. It essentially takes the ELO difference, calculated as the Home team ELO, plus the Home Ground Advantage, minus the Away team ELO, and converts it to a value between 0 and 1. Positive differences in ELO ratings (i.e. for the higher rated team) give us a Expected result of greater than 0.5.

$latex Result_{predicted} = \frac{1}{1 + 10^(\frac{-eloDiff}{M})} &bg=f0f0f0$

$latex eloDiff = ELO_{home} - ELO_{away} + HGA &bg=f0f0f0$

The two main parameters we can set are M and HGA. M is a constant that scales the eloDiff and its influence on expected outcomes. I've used a constant of 400, again borrowing from FivethirtyEight. HGA (Home ground advantage) gives the home team's chances a bump. For my initial ELO rating system, I'm setting this to a constant of of 35, which equates to about 8 points in terms of Margin, which is the long term average for home team outcomes. I hope to eventually update this to be parameterised by updating based on recent experience at a ground or perhaps travel distance, but thats it for now.

You can see, for a range of rating differences (including HGA), the expected outcome. This expected outcome is also what I currently use as my probability[ref] I'm looking to change this for next year, likely to actually model historical ELO rating differences on probability of winning [/ref], so an expected outcome of 0.75 equates to a 75% chance of winning.

![expOutcome](http://plussixoneblog.com/wp-content/uploads/2016/04/expOutcome.gif)

###### Special K

Now that I have mapped Expected and Actual results to values between 0 and 1, I just have to decide on k. The k value allows me to scale how much my ratings are effected by new results. Large values of k are really impressed by new information, while low values of k tend to require more information to move the ratings a lot. It is hard to know what to pick for k without performing some kind of optimisation of this parameter[ref]which I plan to do for my next implementation[/ref]. For now, I tested a few different values and found that 20 gave me the best results - around the same as FiveThityEight's NFL and NBA models.

###### Iterating the ratings

The only other issue to solve is what to do a) when a new team is introduced and b) at the start of a new season. For the first issue, I simply start any new team at 1500 points in their first season. Because ELO ratings are zero-sum after each match, this means that my league average is always 1500. For continuity, I treat Sydney as the same team as South Melbourne and the Brisbane Lions as the same team as the Brisbane Bears.

After each season, I regress each teams ELO rating towards the league average of 1500. This helps to account for things that are inherently built into the AFL such as equalisation, whereby good teams aren't meant to stay good for too long and bad teams aren't meant to stay bad for too long [ref] as far as I know, not empirically tested?[/ref], as well as the myriad of other things that happen during an AFL offseason. I do this at a rate of 60% in that a team will move 60% of the distance between its current rating and 1500. If a team was rated as 1600, they would regress to 1540, while a team on 1400 would regress to 1460. This seems high but I tried a few different values and this seemed to work the best. I plan to optimise this in the next implementation.

$latex ELO_{New Seas} = (0.6\times ELO_{Old Seas}) + ((1-0.6)\times 1500) &bg=f0f0f0$

###### Results!

Now that I've got that out of the way, I can go through each match in the period of the VFL/AFL and get ELO ratings for each team! Below I've plotted each teams ratings over their history. There will be a few posts later on (and, one day, an interactive page) to explore these ratings, but this gives a bit of an idea. I've added a line at 1500 to show where a team is rated compared to the league average.

![teams](http://plussixoneblog.com/wp-content/uploads/2016/04/teams.gif)

I also can use the ELO difference before each game to predict the binary outcome (win/loss), the margin and also a probability. I plan to write another piece on that, but for now, I can report that across the entire history of VFL/AFL, the model has tipped 68.6% of games correctly, with a Mean Absolute Error in the Margin of 26.8 points. We can see that the performance is in general getting worse over time - possibly due to expansion of the league (i.e. more games to get wrong).

![mapeandtips](http://plussixoneblog.com/wp-content/uploads/2016/04/mapeandtips.gif)
