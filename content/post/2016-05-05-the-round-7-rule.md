---
title: The round 7 rule?
author: jamesday87
date: '2016-05-05'
categories:
  - AFL
slug: the-round-7-rule
---

In an article over the weekend, Rohan Connolly from The Age asked if the [finals teams were already set by the end of round 7](http://www.theage.com.au/afl/afl-news/afl-2016-is-the-final-eight-already-done-and-dusted-20160502-gokd93.html). He suggested that Round 7 appeared to be some kind of milestone.

<blockquote>Call it the round seven rule if you like, but in a nutshell, if a team wasn't already in the top eight by then, it was almost certainly not going to be there when the finals began four months later. Just once in that period, in 2005, did the top eight after that arbitrary cut-off point alter by more than one team.</blockquote>

I've often heard commentators discuss this and always wondered if the data support it. It makes sense that better teams are higher on the ladder at Round 7 and therefore across a season end up higher on the ladder as well, but as we know, teams have[ varying difficulties in their draw across a whole season](http://footymaths.blogspot.com.au/p/we-have-posted-before-on-this-blog.html), let alone in the first 7 rounds. It is as uncommon as discussed?

![](http://i2.wp.com/plussixoneblog.com/img/2016/04/RelAndMost.gif?resize=640%2C452)

In my post [last week about Freo](http://plussixoneblog.com/2016/04/28/annus-horribilis-fremantle/), I showed the above chart to highlight how wins in the first 6 rounds seemed pretty predictive of total wins later on. Having a bad start certainly didn't exclude teams from having good seasons, it just made it less likely. The Arc [further explored this idea](https://thearcfooty.com/2016/05/01/how-meaningful-is-a-teams-record-at-this-point-of-the-season/), by estimating the predictive strength of a teams winning percentage after a certain number of games on their final winning percentage. As we might expect, it was shown that the further we get through the season, the better a teams record predicts their final record, however early season wins did give a relatively good indication. In fact, the final figure from the The Arc article shows that after round 7, [a teams record explains around 60% of the variance in their final record](https://thearcfootydotcom.files.wordpress.com/2016/05/regroundsr22.png).

To fully explore the "Round 7 rule" as defined by the article in The Age, I decided to focus on team rankings. Exploring the data for changes in rank from 1994-2015 (i.e. when we've had a final 8), we find 42 teams that have made the 8 from outside it at round 7, an average of just under 2 per season. The top 20 of those, defined as the biggest change in rankings, are plotted below.

![finalRun](http://plussixoneblog.com/img/2016/05/finalRun.gif)

If we take a closer look at the data for each round, rather than just round 7, we can begin to make some inferences about what stage in the season tends to see the ladder "stabilise". Below, I've calculated the mean number of teams that moved into the final 8 after being outside it in through each round (again between 1994 and 2015).
![switch3](http://plussixoneblog.com/img/2016/05/switch3.gif)

Again, as we should expect, the number of teams entering the top 8 drops off as we progress through the season. We see that Round 7 is in fact at the (arbitrary) point where, on average, we first see less than 2 teams tend to move into the final 8. Another a similarly arbitrary threshold is seen as Round 16, where fall below 1 change on average.

The next two plots attempt to quantify the specific relationship between ladder position (i.e. Rank) of each round and the final ladder position. In the first instance, I've used [Spearman's Footrule distance](http://people.revoledu.com/kardi/tutorial/Similarity/FootruleDistance.html), which is essentially the total, absolute difference in ranks, while in the second, I've used [Spearman's rank correlation coefficient](https://en.wikipedia.org/wiki/Spearman%27s_rank_correlation_coefficient), which is similar to a normal correlation coefficient but designed for ranks.

![stabil](http://plussixoneblog.com/img/2016/05/stabil.gif)

In essence, each gives us an estimate of how similar two sets of rankings are - in our case, how similar is the ladder position at round N from the final ladder position. For these analyses, I've used the whole ladder, rather than the final 8, but it didn't make a huge difference focusing on just the top 8, other than some increased variability. We can again see that as we move through the season, the ladder position begins to become more similar to the final ladder position.

So do we see evidence of a threshold point at round 7 to support the idea of the Round 7 rule? Probably not - we see the each subsequent round provides an incremental increase in our ability to predict the final ladder position. Rather than some big "tipping point", it is more of a slow burn. In saying that, considering how far out we are from the finals, an average of less than 2 changes, and a Spearmans rho of 0.75 is pretty good. Rather than a "round 7 rule" is probably more likely that good teams tend to be higher placed after Round 7 than bad teams, and good teams tend to finish higher on the ladder by the end of the season.

EDIT: The Arc also posted a similar analyses with similar conclusions. [Have a read!](https://thearcfooty.com/2016/05/05/how-early-is-the-top-eight-usually-set/)
