---
title: Round 11 Results
author: jamesday87
date: '2016-06-06'
categories:
  - AFL
  - Results
slug: round-11-results
---

After a few weeks struggling to juggle and balance various commitments, I think I've finally got into enough of a routine and automated enough of my R scripts that I can release my ELO ratings update early in the week and put my predictions out later in the week! I'll also hope to write a bit more interesting post mid-week such as my one on [the Tackle Machine](http://plussixoneblog.com/2016/05/18/the-tackle-machine/), or the [Round 7 rule](http://plussixoneblog.com/2016/05/05/the-round-7-rule/). Here's hoping anyway!

Anyway, after 4 weeks in a row tipping 6 out of 9 winners, my [ELO model ](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/)has had its first official perfect round, correctly tipping 9 winners over the weekend! It helped that the favourite got up in 8 of the 9 rounds, making it a relatively easy week to tip, but like a proud parent, that doesn't bother me in the slightest! The MAE for this week was 29 points, bring the season total to 73 correct tips (73.7%) with an MAE of 30.53.

The updated ELO ratings are below and, for the first time since Hawthorn lost the 2014 Grand Final, they are no longer the top team in our ratings! With Adelaide's trashing of the Saints, and Hawthorn not putting Melbourne away by as much as expected, the Crows leapfrogged the Hawks into top spot! Port Adaide and North Melbourne also impressed our model, bridging the gap to the other top teams, with a relatively close group of 9 teams now clear of the rest of the pack.

![ELO_postR11](http://plussixoneblog.com/img/2016/06/ELO_postR11.gif)

Our simulated ladder still favours Sydney, obviously taking into account their rating of 3rd, their current record and remaining draw, with North Melbourne also jumping up into 2nd spot by average. The model still has trouble splitting the make up of the top 8, but is getting pretty certain that no-one apart from Port Adelaide can jump up into the 8. For Port, their win on the weekend gave them a nice bump in ratings and lifted their percentage of top 8 finishes to 45% in our rating system.

![round12to23](http://plussixoneblog.com/img/2016/06/round12to23.gif)

We are also starting to see some different shapes emerge in our distribution plots for seasons, essentially signalling that the model is more certain about where some teams will finish than others. Hawthorn and North, for example, despite winning on the same amount of wins, show different distribution shapes. It will be interesting to see how this changes during the season.

![round11SimDist](http://plussixoneblog.com/img/2016/06/round11SimDist.gif)
