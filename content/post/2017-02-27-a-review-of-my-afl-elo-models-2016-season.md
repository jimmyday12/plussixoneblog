---
title: A review of my AFL ELO model's 2016 season
author: jamesday87
date: '2017-02-28'
categories:
  - AFL
slug: a-review-of-my-afl-elo-models-2016-season
---

I introduced my [ELO ratings](http://plussixoneblog.com/elo-rating-system/) last year slightly after the start of the season. While my main motivation was to implement a system that allowed for more objective team ratingsthat allows for some interesting comparisons and analyses of team performance[Ref]More to come on this![/ref], it is worth doing a review of the predictive performance of the system before we start this season. My model started the season with a somewhat arbitrary goal of tipping above 70% and keeping our mean absolute prediction error (MAPE) below 30.

So how did our model go?

<!-- more -->

### Tipping performance

In terms of raw tipping, we acheived a total of 146 out of 207 (70.5%). I did attempt to look up the results from some public footy tipping sites but none of them seem to make their historical results available[Ref]Anyone with any ideas feel free to let me know on Twitter[/ref].

![plot of chunk results](http://plussixoneblog.com/wp-content/uploads/2017/02/results-1-14.png)

### Margin results

While tipping is generally considered more fun, one of the cooler aspects on my model is the ability to objectively predict margins and probabilities. These are certainly what I get more interested in week in week out. As mentioned, I set my model an arbitrary target of getting a MAPE under 30 points for the year, which my model managed just with 29.3. As the chart below shows, this measure varied widely throughout the season.

It is interesting to note that (excluding the grand final), my model tipped at least 6 winners in 4 out of its 5 worst performing MAPE rounds! This shows relative harshness of a team performing wildly different to my model in terms of MAPE. While it only loses 1 correct tip by a team outperforming their rating, it can be punished with a high margin error.

![plot of chunk MAE](http://plussixoneblog.com/wp-content/uploads/2017/02/MAE-1-14.png)

Another way to look at the margin prediction is to assess how the actual margin compared to our prediction margin. The plot below shows this.  The general trend is that higher predicted margins are associated with higher actual margins.

![plot of chunk Predictions](http://plussixoneblog.com/wp-content/uploads/2017/02/Predictions-1-14.png)

### Probability of winning

Finally, we can assess the performance of our Probability predictions. If our probability predictions were good, then we would expect, on average, that when we assign a probability of say 50% to a team winning, then that team would win roughly 50% of the time. While seemingly intuitive, this is something that most sport fans, and [people in general](https://arstechnica.com/science/2011/06/risk-probability-and-how-our-brains-are-easily-misled/), are really bad at understanding. [The Arc](https://thearcfooty.com/2017/02/07/win-probability-estimates-what-are-they-good-for/) and [Matter of Stats](http://www.matterofstats.com/mafl-stats-journal/2017/2/8/in-running-models-their-uses) both wrote great pieces discussing this recently, which I encourage you to read.

To make this assessment, I've split up each match into 25 equal size bins, each representing a mean probability assigned to the home team by my model for games within that bin. I've then worked out the actual probability of games won by teams within each of those bins. A perfectly calibrated model has a 45 degree line from 0 to 100%. While we don't quite have that, we again see a pretty good trend. Teams who our model has assigned a small probability too tend to win at a much lower rate than those who we assign a high probability to.

![plot of chunk Calib](http://plussixoneblog.com/wp-content/uploads/2017/02/Calib-1-14.png)

I won't be changing anything in the model this year (although I do have plans to start to tweak things) so we will see how this goes moving forward into 2017. I'll likely keep a similar analysis of the tipping performance as the season progresses so you can check in during the year to see how we are going.
