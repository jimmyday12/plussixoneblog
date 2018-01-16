---
title: Introducing the AFL womens rankings
author: jamesday87
date: '2017-02-03'
categories:
  - AFL
  - AFL Womens
slug: introducing-afl-womens-rankings
---

Unless you've been too distracted by US politics, you should know that tonight marks the start of a pretty big step forwards in women's sport in this country. The AFL women's competition has finally arrived!

<!-- more -->

When it first got announced, I decided that I'd like to try to include it in my blog. There is plenty of content around celebrating the amazing stories around some of these athletes and I encourage you to read as much as you can. Some of my favourites are below:

  * [The start of the AFL women's competition is a great and bittersweet moment](https://www.theguardian.com/sport/2017/feb/02/a-game-of-their-own-aflw-has-given-womens-footy-a-sense-of-authority-and-authenticity)

  * [AFL footy by and for women: our rules, our game, our story](https://www.theguardian.com/sport/2016/sep/05/afl-footy-by-and-for-women-our-rules-our-game-our-story)

  * [Growth of women's football has been a 100-year revolution – it didn't happen overnight](https://theconversation.com/growth-of-womens-football-has-been-a-100-year-revolution-it-didnt-happen-overnight-71989)

One of the tricky things however is that, being a 'data driven' blog, there is certainly a lack of freely available data for this competition. The uncertainty is probably part of what makes this new competition pretty exciting, notwithstanding the awesome opportunity it affords female athletes, but it does make any data driven analysis tricky. I encourage you to read the Hurling People Know blog who last year did a great job of [delving into the little data available](https://hurlingpeoplenow.wordpress.com/2016/11/09/aflw-power-rankings-november-2016).

### Women's ELO model

I'll attempt throughout the year to provide some interesting insights into the comp as it evolves. The main thing I'll be doing is running a simple ELO model. I've been running one for the Men's comp for a year now. You can read more about it [here](http://plussixoneblog.com/elo-rating-system/) but for those who've read the methodology, you'll know that we have to set a few parameters.

Without much data to go off, I'm going to be setting most of these the same as the men for our Women's ELO. After a bit more data, I'll look to optimise them but this is a good start. One parameter that I'm interested in however is the starting ratings. You may recall that for the Men, I set this at 1500, which is the league average. While this probably isn't correct to begin with, without much more information it is tricky to justify otherwise.

### Initial ratings

Footy Math [wrote a nice preview of his AFLW ratings](http://footymaths.blogspot.com.au/2017/01/nwl-1-launch.html) and he is actually running two side-by-side systems - one with a default starting value for each team and one using a subjective rating system. Troy Wheatley is running with a combination of his Men's [rankings and the premiership odds](http://troywheatley.blogspot.com.au/2017/01/introducing-afl-womens-power-rankings.html).

Before I decide, I thought I'd explore how long it takes a team's rating to stabilise? Given that we set every 'new' team to be the average, they generally separate from that pretty quickly. Does it take a long time or is that relatively quick?

Firstly, I've taken each teams ELO rating over the first 100 games they player and plotted it blow. I've applied a bit of [loess](https://en.wikipedia.org/wiki/Local_regression) smoothing to make the graph a little neater.

![plot of chunk ELO new](http://plussixoneblog.com/wp-content/uploads/2017/02/ELO-new-1.png)

While there probably isn't a general trend, a few things are apparent.

  * A few bad teams really drop off quite quickly (these were GWS, Gold Coast and St Kilda).

  * Not many teams go 'above' average for extended periods in their first 100 games.

  * There isn't really much consistency but the spread of teams is pretty much equal from about 20-25 games.

Another way to look at this is to use the 'change in ELO' of each team. The change in ELO represents how different the result was from our expectation. Given we set each team at the arbitrary 1500 mark, we would expect that this would improve over team as teams get closer to their "true" ELO rating[ref]this probably doesn't exist since team levels are changing so much over time due to form, injuries, lucky etc[\ref].

![plot of chunk delta_elo](http://plussixoneblog.com/wp-content/uploads/2017/02/delta_elo-1.png)

It certainly doesn't look like the change in ELO changes much over time? What about the mean absolute average (note, I only take the home team since this is offset by the opposite change in rating of the away team).

![plot of chunk datsum](http://plussixoneblog.com/wp-content/uploads/2017/02/datsum-1.png)

Interestingly, the change in ELO trends upward over the first 100 games. Thinking about this now however, it does kind of make sense. Firstly, by setting teams up with a starting position of 1500, we are condensing them close to the average team. While some teams will outperform this, generally, most teams sit around this average number. So, we do in fact see ratings take a little while to get going. After a season or two, a lot of new teams tend to improve and so it's likely we see the change in ELO jump up, following this improvement.

### Finally, the ratings!

Perhaps because I'm running out of time, or perhaps the data has convinced me, but I'm going to remain with my initial ratings of 1500. They don't take too long to stabilise and it is safer to assume each team is 'average' until we have more information. I would have liked to have explored using the premierships odds, but that might wait until next week.

I'm not going to do a plot for that but you can find my tips and ratings [here](http://plussixoneblog.com/current-afl-womens-ratings-predictions/) and I'll keep that page updated as the season progresses! Enjoy the footy tonight and hopefully this is the start of something special!
