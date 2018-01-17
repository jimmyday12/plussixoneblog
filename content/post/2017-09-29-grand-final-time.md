---
title: Grand Final Time!
author: jamesday87
date: '2017-09-29'
categories:
  - AFL
slug: grand-final-time
---

Onto our last game of the season and what a pretty awesome matchup! The craziness that is the Tiger train marched on while the Crows, most peoples 'best team all year' tries to spoil the Richmondy army. Last year I wrote a little preview that showed the path to the grand final of each time - I've dug up that old code and shown the same below. Happy reading!

<!-- more -->

## The path to glory

We can see below that both teams have taken different paths this year. Adelaide started the year near the top of our rankings and have been pretty consistant in their rating, apart from a significant drop after round 7 and 8, where they lost to North Melbourne and Melbourne by significant margins. The Tigers on the other hand have been slowly building all season. It wasn't until mid year they actual broke through the 'average' team barrier of 1500. Interestingly both teams have been on a nice upward trend since July - coinciding with really strong finals performances.

![plot of chunk paths1](http://plussixoneblog.com/static/img/2017/09/paths1-1.png)

We can extend these out a bit to try and look at where these teams have come from over the last few years. Adelaide has been on the up since late 2015. The Tigers 2016 season really was terrible! As noted in the media this week - from where they were placed at this point last year it's a pretty meteoric rise.

![plot of chunk paths2](http://plussixoneblog.com/wp-content/uploads/2017/09/paths2-1.png)

Where do these teams fit in the grand scheme of things? Adelaide is now our clear number one rated team. Richmond has risen the ranks rapidly over the last few weeks to sit in 3rd.

![plot of chunk ratings](http://plussixoneblog.com/wp-content/uploads/2017/09/ratings-1.png)

## Prediction

Given these ratings - what are we predicting this match? Well, with a superier rating and the nominal 'home team advantage', we are tipping the Crows by 21. Percentage wise, this equates to a 62.9% probability of a Crows win It has long been a bear bug of my model that I use nominal home team rather than some kind of measure of experience at the ground but nonetheless, it's served me pretty well.

![plot of chunk unnamed-chunk-1](http://plussixoneblog.com/wp-content/uploads/2017/09/unnamed-chunk-1-1-3.png)

So there you have it. The Crows have up there in our ratings all year. They are clearly the best performed team of the year. But Richmond is trending rapidly upwards and riding a pretty big surge of emotion! All the best to supporters of both teams. It's been a fun year (even though I've struggled with time) and I look forward to touching base next year. Stay tuned on Twitter for an exciting little project :)

## Table

Ignore this. It's for Squiggle purposes :)

```r
predWide <- roundPredictions %>%
        select(Date, Game, Round, TeamStatus, Team, ELO, Margin, Outcome) %>%
        mutate(TeamStatus2 = paste0(TeamStatus, ".ELO"),
               status = TeamStatus,
               Game_all = Game,
               Game = Game - min(Game) + 1
               ) %>%
        spread(TeamStatus, Team) %>%
        spread(TeamStatus2, ELO) %>%
        group_by(Game) %>%
        arrange(Game, status) %>%
        mutate(Away = lag(Away),
               Away.ELO = lag(Away.ELO),
               ELOdiff = Home.ELO - Away.ELO) %>%
        filter(status == "Home") %>%
        ungroup() %>%
        select(Round, Game, Game_all, Date, Home, Home.ELO, Away, Away.ELO, Margin, Outcome) %>%
        mutate(Probability = percent(as.numeric(Outcome)),
               Margin = as.numeric(Margin),
               Result = ifelse(Margin > 0, paste0(Home, " by ", abs(Margin)), paste0(Away, " by ", abs(Margin))),
               Label = paste(Home, "v", Away),
               Date = format(Date, "%a, %b %d")) %>%
        select(-Outcome)

ft <- formattable(predWide,
                  list(Probability = color_tile("white", "#996666"),
                       area(col = c(Home.ELO, Away.ELO)) ~ normalize_bar("#669999", 0.2),
                       Margin = formatter("span", style = x ~ style(color = ifelse(x > 0, "#669999", "#996666")))
                  )
)

ft
```

<table class="table table-condensed" >

<tr >
Round
Game
Game_all
Date
Home
Home.ELO
Away
Away.ELO
Margin
Probability
Result
Label
</tr>

<tbody >
<tr >

<td style="text-align: right;" >27
</td>

<td style="text-align: right;" >1
</td>

<td style="text-align: right;" >15200
</td>

<td style="text-align: right;" >Sat, Sep 30
</td>

<td style="text-align: right;" >Adelaide
</td>

<td style="text-align: right;" >1650
</td>

<td style="text-align: right;" >Richmond
</td>

<td style="text-align: right;" >1593
</td>

<td style="text-align: right;" >21
</td>

<td style="text-align: right;" >62.94%
</td>

<td style="text-align: right;" >Adelaide by 21
</td>

<td style="text-align: right;" >Adelaide v Richmond
</td>
</tr>
</tbody>
</table>
