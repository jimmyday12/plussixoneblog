---
title: Annus horribilis Fremantle
author: jamesday87
date: '2016-04-28'
categories:
  - AFL
slug: annus-horribilis-fremantle
---

By his own words, Ross Lyons team have are having an Annus Horribilis[ref]much to my dismay, that word doesn't have the low brow meaning I had hoped - instead it means ["horrible year"](https://en.wikipedia.org/wiki/Annus_horribilis))[/ref]. It doesn't take a whole lot of in depth data to know that starting the year with 0 wins and 5 losses is bad, and there is no shortage of stories describing just how bad that is.

[The Arc](https://thearcfooty.com/) shared a great visualisation looking at the [progression of wins by minor premiers in the year following their minor premiership](https://thearcfooty.com/2016/04/26/the-worst-seasons-ever-by-reigning-minor-premiers/). Only Richmond in 1983 has started 0-5 from minor premiers, while the worst final season record is the Kangaroos in 1984, who won 5 games all year.

Where do we think Freo might get to? I thought I'd further explore the Dockers poor start by comparing to some other historical distributions to see just how bad it is. Below I've plotted the distribution of games won after 5 rounds, where we see, as we expect, a relatively normal distribution across those 5 games. Approximately 7.9% of teams, regardless of quality, begin a season at 0-5 in the history of the AFL (this drops to around 6% if we just look at 1990 to 2015).

![1DistStart](http://plussixoneblog.com/wp-content/uploads/2016/04/1DistStart.gif)

Looking at how these groups of teams finished the season, we can see that early wins (i.e. games won after 5 rounds) seems pretty predictive of absolute final wins by season end. Of course, within those final wins is included the early wins, but removing them and showing 'relative' final wins (i.e. the record after round 5) shows a similar pattern.

![RelAndMost](http://plussixoneblog.com/wp-content/uploads/2016/04/RelAndMost.gif)

Focussing just on the top graph, where we have our 0-5 teams, it becomes apparent that very few teams who start 0-5 end up turning their season around. Below, I've picked out the best performing teams, in terms of final wins, after starting 0-5 [ref]In reviewing this graph, it revealed a slight error in my methodology as some teams such as North Melbourne in 2011 didn't start at 0-5 but in fact had 0 wins after round 5, with a bye. I may try and fix this later on but I suspect it won't change things a whole lot[/ref]

![05starters](http://plussixoneblog.com/wp-content/uploads/2016/04/05starters.gif)

The data show that only two teams have won 12 games,[often discussed as the finals cutoff](https://www.bigfooty.com/forum/threads/how-many-wins-to-make-the-finals.936317/)[ref]I sense a good blog post coming![/ref] after starting 0-5 - Richmond in 1924, who happened to [win the final game of the Finals that year but didn't win the premiership](https://en.wikipedia.org/wiki/1924_VFL_season#cite_ref-2) and Collingwood in 1959, interestingly the premiers from the year before.

So, against historical data, Freo has a pretty huge task ahead of them to make finals. This does however fail to take into account many factors. Maybe other teams who start 0-5 are just really really bad teams and Freo isn't? Perhaps Freo has had a really tough start to the season in terms of opponents ([they don't appear to across the season](http://www.matterofstats.com/mafl-stats-journal/2015/12/7/the-2016-afl-draw-difficulty-and-distortion?rq=draw)) compared to the general 0-5 team?

Luckily, we can try to account for such things by using a rating system, such as my ELO ratings, which allows us to simulate expected results based upon the inherit skill and form of a particular team. Below, I've simulated a season 10000 times for the 1st 5 rounds and the rest of the season. The 1st 5 rounds are based on our [pre-season rankings](http://plussixoneblog.com/2016/04/28/start-of-2016-season-afl-elo-ratings/) for Fremantle (we had them 9th) and their draw. We saw them start 0-5 around 3.7% of the time, below the historical average discussed above, and had them on average finishing with 2.7 wins on average.

![FreoSim](http://plussixoneblog.com/wp-content/uploads/2016/04/FreoSim.gif)

From here on in (i.e. simulating their season from R6 onwards), we can see that, like historical teams that start 0-5, we don't give Freo much chance of moving up the ladder. They do seem to fare slightly better than the average 0-5 time however and they do get at least 12 wins 8.7% of the time, which is higher than our historical 0-5 teams. Either our model has been too slow to adjust to Freo's lack of ability or they aren't your typical 0-5 team!

A lot of this assumes that Freo will continue to try and win as many games as possible, which may not be the case. Nonetheless, if anyone can turn a team around, and provide them with an [Annus Mirabilis](https://en.wikipedia.org/wiki/Annus_mirabilis) one might expect a coach like Ross Lyon, known for getting every inch out of his list, might be able to do it. At least our current rating of Freo (as the 10th best team) gives them a small chance. That is if Ross doesn't jump ship early!
