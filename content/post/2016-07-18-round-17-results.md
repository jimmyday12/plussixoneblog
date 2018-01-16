---
title: Round 17 Results
author: jamesday87
date: '2016-07-18'
categories:
  - AFL
  - Results
slug: round-17-results
---

As the season starts to heat up, we are getting some interesting games in the context of the season, as noted last week by the super important Sydney v Hawthorn game. In combination with a really tight top 8, whenever two top 8 teams are matched up, my [ELO model ](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/) has difficulty separating them. Nonetheless, we continued on with an OK 6 out of 9 games tipped correctly, with a respectable MAE of 22. Our 3 misses were all ones that our model predicted to be close, with Sydney (54% chance), North Melbourne (56% chance) and Melbourne (54% chance) all losing. This gives us a season total of 105 tips from 144 games (73%) and an MAE 28.6.

![ELO_post17](http://plussixoneblog.com/wp-content/uploads/2016/07/ELO_post17-1.png)

One note of interest is I've had to adjust my scale for this plot because of Brisbane doing so badly. I might write a bit of a historical piece comparing them to other badly performing teams.

Given the tightness of the MAE this week, we didn't see many big jumps in our rating system. The two most notable movers are Port Adelaide and North, who swapped places this week (7th and 9th, respectively). North has now almost dropped to the level of an average team (1500) and face a big matchup against a similarly rated Collingwood this weekend. I haven't released my full match importance ratings but the Friday night clash between North and Collingwood is big for North's chances of holding onto their top 8 position.

<blockquote>

>
> [@RyanBuckland7](https://twitter.com/RyanBuckland7) [@MatterOfStats](https://twitter.com/MatterOfStats) In sims where they win this week, they make top 8 74% of the time. When they lose, it drops to 40%.
>
>
— plusSixOne (@plusSixOneblog) [July 18, 2016](https://twitter.com/plusSixOneblog/status/754844423788257280)</blockquote>

I briefly noted last week that my [match importance rating](http://plussixoneblog.com/2016/06/16/beyond-the-8-point-game-estimating-match-importance-in-the-afl/) was very high on the Sydney v Hawthorn game last week, which can be seen the Swans' chances of top 1 and 2 taking about a 15 point hit. Their top 4 chances interestingly didn't change too much (dropping from 65% to 58%), probably as North and WCE chances of going on a run and getting into the top 4 are getting smaller.

![simTableR18](http://plussixoneblog.com/wp-content/uploads/2016/07/simTableR18-1.png)

The biggest drop from the weekend was easily North Melbourne, whose chances for top 8 dropped from 76% to 62%. The main beneficiaries for that were Port Adelaide - jumping from 20% to 31% and St Kilda, who are now into double figures. We've also seen Freo now _mathematically_[ref]at least in my 10000 simulations they don't make it once[\ref] falling out the race for the top 8.
