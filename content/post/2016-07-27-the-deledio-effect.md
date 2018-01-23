---
title: The Deledio Effect - can Richmond win without him?
author: jamesday87
date: '2016-07-27'
categories:
  - AFL
slug: the-deledio-effect
---

After the weekend, in which Richmond lost handsomely to (a very good) Hawthorn side, the narrative trotted out by the football media again seemed to surround the idea that Brett Deledio didn't play. Every time he doesn't play and Richmond lose, we generally get given some cherry picked data about how many games Richmond has lost while he hasn't played. While it may be the case that he is super important to Richmond, simply stating their win/loss record without him doesn't show this. I thought I'd use this opportunity to explore the issue slightly more in depth!

<blockquote>

>
> DELEDIO EFFECT [@Richmond_FC](https://twitter.com/Richmond_FC) have lost 15 of the 18 games [@BrettDeledio03](https://twitter.com/BrettDeledio03) has missed in his career [#AFLHawksTigers](https://twitter.com/hashtag/AFLHawksTigers?src=hash) [pic.twitter.com/KykOBShIWV](https://t.co/KykOBShIWV)
>
>
— AFL on 7 (@7AFL)

[July 24, 2016](https://twitter.com/7AFL/status/757114999319830528)</blockquote>

My general belief is that while the make up of a team is important (as we can clearly see from Essendon this year, after losing half of their list), the marginal gains that one player may provide are quite small compared to our overall beleif about a teams gross ability. My [ELO model](http://wp.me/p7soFv-3G), which is ignorant to team make up, can do a pretty good job of predicting match outcomes. Nonetheless, data from overseas has begun to explore the idea of using Network Analysis to understand team makup. In fact, in AFL, Sargent and Bedford published research using [Interactive Network Simulation Geelong's 2011 season](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3761758/) to understand the impact an individual player inclusing or exclusing from a lineup had on a team.

![](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3761758/bin/jssm-12-116-g004.jpg) **Interactive Network Simulation of the effect of Bartel on the Margin**. Figure taken from [Sargent and Bedford](http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3761758/). _J Sports Sci Med_. 2013; 12(1): 116-121

While I don't have the time or expertise to implement their Network analyses (yet), I can use my ELO model to gain a better understanding of the specific effect of having Deledio has on our _expected_ outcome, rather than simply expecting them to win every game he plays in. Since I've got a model that does a pretty good job over a season of applying a probability to a particular matchup based on the relative rating assigned to a team (independant of the players involved), Ive got a nice tool to compare how Richmonds winning rate compares to what we would expect from a team of Richmonds level compared to how they have actually performed without Deledio.

The first thing we need to know is which games have Richmond played in during Deledios career where he did and didn't play. I've used data [afltables](www.afltables.com), to come up with all Deledio-less games. Knowing this, we can now take a look at Richmonds record in the time since Deledio's debut in Round 1, 2005. In the **262** games that Richmond has played in since his debut, he has missed **19**, with Richmond only winning **3** of them, a rate of **15.79%**. This is on contrast to his career winning percentage of **45.27%** over **243** games. It is this descrepancy that is often terrmed the _Deledio Effect_.

![plot of chunk winsPlot](http://plussixoneblog.com/img/2016/07/winsPlot-1-3.png)

The first thing we note here is how small our sample size is for games in which Deledio missed, compared to those in which he won. We could probably just stop our analyses here and make a statement about how we need more information to better understand the true impact of having Deledio has on the Tigers. But as promised, I've got my [ELO model](http://wp.me/p7soFv-3G) that can at least give us a slightly deeper understanding about how anomalous this result is.

Below, I've taken the expected margin computed from the difference in ELO rating (plus a home ground advantage boost) for those games in which Deledio missed and plotted those expected Margins against the actual margins.

![plot of chunk marginPlot](http://plussixoneblog.com/img/2016/07/marginPlot-1-3.png)

This plot again shows that there is really a very small dataset to work with for the missing data. It also shows that when he does play, our model does a pretty good job at predicting the margin on average, with an MAE of **31.3** for when he does play. Tentatively, this value is slightly higher when he doesn't play (**36.2**), although, n = small.

In those games where he does miss, we can see that there is a _relatively_ big proportion of games in the quadrant where we predicted a win but saw a loss (highlighted as blue), suggesting that these are the games where the Tigers underperformed against our models expectations.

To attempt to further explore this data, I've performed some simulations (you can read about the methodology [here](http://wp.me/p7soFv-3G)) on the Tigers games during Deledio's career. Breifly, I use the difference in ELO ratings between the two teams to estimate a predicted margin. I then draw an actual simulated Margin from a normal distribution with a mean of that expected margin and some noise. I've then repeated this 10000 times for each game during the Deledio era. You can see the distribution of wins for each category (Missed v Played) below.

![plot of chunk distributionPlot](http://plussixoneblog.com/img/2016/07/distributionPlot-1-3.png)

We can see that our distribution of wins for the Missed games centers around 10 (a percentage of **52.63%**), well above our actual wins of **3**. In fact, we only saw 3 wins or less in **0.05%** of our simulations! In games where he played, this rises to a **76.87%** in games where he does play, suggesting that Richmond actually outperform expectations in those games.

### Conclusion

So what can we conclude? I started off convinced I could debunk the Deledio myth but our data hasn't helped. There is a lack of data points where Deledio doesn't play, so making definitive inferences is probably not valid. We can conclude however that in games where Deledio doesn't play, Richmond perform well below where we'd expect them. In games where he does play, Richmond perform well above where we'd expect them. My speculation for possible explanations are

  * **Unexplained variance**

This whole analyses is based upon my [ELO model](http://wp.me/p7soFv-3G), which does a pretty good job of predicting outcomes (~70% of games tipped correctly, better than chance) and margins (a long term Mean Absolute Error of 30 points). However, at least in the Margins, it still only explains about 27.48 of the variance in the final margin. That leaves more than 2/3 of the variability unexplained (slightly worse than what [Matter of Stats has shown](http://www.matterofstats.com/mafl-stats-journal/2014/1/14/the-ten-most-surprising-things-ive-learned-about-afl-so-far), but in the same ballpark). Some of that variability may come from Deledio missing, but more likely (especially with our small dataset) is that a combinatino of lots of factors is bringing that variability

  * **Randomness**

Related somewhat to the above point, but sometimes events that we attach small probabilities to actually occur. In fact, given enough time, we fully expect that they will occur, we just don't know when. So even though we'd only expect the Tigers to win 3 games or less based on our [ELO model](http://wp.me/p7soFv-3G) <1% of the time, it still did happen. Maybe we've just seen an extreme run of abnormal results.

  * **Deledio is super important!**

The final take away may be that Deledio is actually important. In the Sargent and Bedford paper I referenced earlier, they used an example of taking Jimmy Bartel out of the Geelong team and replacing him with Shannon Byrnes. This showed a net effect on the mean margin of a game to be 15 points to the score, highlighting how important Bartel was to that Geelong side. Maybe Deledio is actually that important compared to the player who does come into him.

Hopefully with some more knowledge, and data, I can further explore this idea using a similar methodolgy. For now, lets just say that Richmond underperform from what we expect when Deledio doesn't play and leave it there.
