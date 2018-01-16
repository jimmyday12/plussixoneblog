---
title: Beyond the 8 point game - estimating match importance in the AFL
author: jamesday87
date: '2016-06-16'
categories:
  - AFL
  - Simulation
slug: beyond-the-8-point-game-estimating-match-importance-in-the-afl
---

As I was watching an enthralling match between [Western Bulldogs and Port Adelaide](http://www.afl.com.au/match-centre/2016/12/port-v-wb) over the weekend, there was a lot of discussion about how important the match was - the Bulldogs needed to win to cement their spot in the top 8, while Port needed to win to have any chance of jumping up. It's also not uncommon for commentators to discuss the notion of an "[8 point game](http://www.adelaidenow.com.au/sport/afl/teams/adelaide/afl-2016-adelaide-crows-come-from-behind-to-beat-west-coast-by-29-points-at-subiaco-oval/news-story/41fc1204f40f383306830f9133f0ee41?nk=1408436fc4ec653adf780a0bfbb05cb3-1466055655)", typically when two teams close on the ladder play each other.

It got me to thinking about whether 'match importance' was an empirical measure that we could define? I stumbled upon an article entitled "[The Importance of a match in a tournament](http://dl.acm.org/citation.cfm?id=1323912)", which tried to answer this question in the context of the Premier League. While I confess I don't understand a lot of the maths in the paper, a lot of which actually dealt with their predictions of matches, the general idea of measuring 'importance' was pretty simple. By looking at the change in the probability of a team winning the premier league based upon the result of the match, we gain a relative measure of importance for that particular team, in that particular match in the context of their season. In slightly more technical terms, we can use the difference in conditional probability of winning the league between the conditions of winning or losing a particular match to estimate the relative importance of that match.

$latex Importance(X_{team,match}) = Pr(X_{team}|Win_{team,match}) - Pr(X_{team}|Loss_{team,match})&bg=f0f0f0$

The above can read as the Importance of a particular match, for a particular team achieving outcome X (e.g. winning the league) is given by the probability of that team achieving X given (the "|" symbol) they win the particular match minus the probability that they achieve X given they loss the particular match. So if winning a particular match gives Team A a probability of winning the league of 40%, while losing the match gives them a probability of winning the league of 10%, the relative importance of that match is 0.3.

While estimating these specific probabilities over such a long time period is difficult (e.g. what is the probability that Hawthron will finish 1st as of round 12, 2016?) - [our ELO simulations](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/) that we run each week give us pretty good starting point. In fact, [that specific question yields an estimate of 23%](http://plussixoneblog.com/2016/06/14/round-12-results/), based upon running a [Monte Carlo simulation](https://en.wikipedia.org/wiki/Monte_Carlo_method) of the 10 000 seasons and using the proportion of times that result was achieved as our probability estimate. We can use these simulations with the above formula by simply splitting them into two groups for each team - ones where they win the match in question and ones where they lose it, and then use the proportion of times our measure of interest (notionally X in our formula) occurred as our probabilities.

This measure is something I'll report each week but to explore it in this post, I'll use Round 12, 2016 as an example. This round was a round that saw some very close and difficult to predict matches, each of which felt quite important in the scheme of the league. In particular, close matches between top 8 teams occurred such as North Melbourne v Geelong, Adelaide v West Coast, GWS v Sydney and even Western Bulldogs v Port Adelaide (the latter of which is trying to [beat the odds and jump into the 8](http://plussixoneblog.com/2016/05/05/the-round-7-rule/) this year).

The table below shows the Importance measure for each team ahead of round 12 for the range of outcomes I typically report in my simulations.

![round12Importance](http://plussixoneblog.com/wp-content/uploads/2016/06/round12Importance.gif)

Taking the Bulldogs v Port game as an example last week - from the Bulldogs perspective, in simulations where they won that match, they finished top four 64.8% of the time, while in simulations where they lost that match, they finished top four 37.4% of the time. Thus, the relative importance (for top four) for the Bulldogs is 27.5. For Port Adelaide, the match didn't have a big bearing on their top 4 chances (influence score of 8.6), mostly because their chances of making the top 4 are so low anyway, but did have a big bearing on their top 8 chances (influence score of 29).

You'll see from that table that In order to pick an 'influence' score for an actual game, I need to decide which X I choose in my calculation - essentially my output measure for the season. I could choose Top 1, as in the Scarf et al paper, but we don't have as high of an importance on finishing on top of the ladder as the Premier League since we have a finals series. However, choosing just a Top 8 for instance may also not be that interesting, particularly if we expect the [Top 8 to not change from here](http://plussixoneblog.com/2016/05/05/the-round-7-rule/).

At least for me, I feel that subjectively, matches that can also have an influence of the make up of the 8 are quite important. As such, I've decided[ref]at least for now, I may end up using 'sum' as we progress through the season[/ref] to take the maximum importance measure for each team across the values in the table above (Top 8, Top 4, Top 2 and Top 1) to give an idea of the maximum effect this result of this match might have on that teams change in position. I'll then add these two values together for the teams taking place to give an idea of the overall match importance.

![round12MatchImportance](http://plussixoneblog.com/wp-content/uploads/2016/06/round12MatchImportance.gif)

Not surprisingly, the importance of matches is much higher for the better teams in the competition, so it will be interesting to explore how this measure changes over the course of the season. I may also revisit round 12 as, at least the general feeling I had while watching and reading about it, it seemed like quite an important one!
