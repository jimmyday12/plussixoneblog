---
title: Grand Final Preview
author: jamesday87
date: '2016-09-29'
categories:
  - AFL
slug: grand-final-preview4
---

So we enter our final round of the year with a tantalising matchup between the long-suffering Bulldogs and the über consistent Swans. It is fair to say that the two teams have had very different paths to the finals - the Swans finishing minor premiers and being high up in our rankings all year. The Dogs never really climbed much higher than 6th in our rankings all year and have battle both injury and variable form.

<!-- more -->

## The path to glory

How different were these paths? Below, I've plotted both teams ELO rating throughout the season. We can clearly see that the Swans have built from about halfway through the year to emerge as the team our ELO model is most impressed with. On the contrary, the Bulldogs 2nd half to the season has been one of constant decline, losing ELO points nearly every week up until finals. What I find interesting is that the two teams were basically even at Round 12, with only 4 rating points separating them!

Also interesting is the sharp uptick for the Bulldogs in September. This clearly shows their performance in finals has been extraordinary and above expectation. It also perhaps suggests that they are hitting form at the right time of year (although our prior expectation is still that they are not as strong as Sydney)[ref]as a side note, I've decided to include my `R code` for those following along. It isn't 'reproducible' as such as I've got a few custom functions that I'm calling but I'm hoping to get to that point by creating an AFL package that I can share![/ref]

```r
# Create tag for the two GF teams
dat <- dat %>%
        mutate(gf = Team %in% c("Sydney", "WB"))

# Create ggplot
gg<-ggplot(filter(dat, !gf & Season == 2016), aes(x = Date, y = ELO_post, group = Team)) +
        geom_step(alpha = 0.5, color = "grey") +
        geom_step(data = filter(dat, gf & Season == 2016), alpha = 1, aes(color = Team)) +
        theme_fivethirtyeight() +
        labs(title = "Diverging seasons",
             subtitle = "ELO rating of Bulldogs and Swans throughout the season")

# Add plussixonebanner
gg<-addBanner(gg)
```

![plot of chunk paths1](http://plussixoneblog.com/wp-content/uploads/2016/09/paths1-1-2.png)

We can extend these out a bit to try to look at where these teams have come from over the last few years. Clearly the storyline of the Bulldogs is one that they have risen rapidly up the ranks. What is less apparent is that the Bulldogs (at least according to our ELO model), actually had that rapid rise last year. They in fact started this year more highly rated than they finished it!

```r
# Create ggplot
gg<-ggplot(filter(dat, !gf & Season > 2013), aes(x = Date, y = ELO_post, group = Team)) +
        geom_step(alpha = 0.5, color = "grey") +
        geom_step(data = filter(dat, gf & Season > 2013), alpha = 1, aes(color = Team)) +
        facet_wrap(~Season, scales = "free_x") +
        theme_fivethirtyeight() +
        labs(title = "The path to glory",
             subtitle = "ELO rating of Bulldogs and Swans throughout the last 3 seasons")

# Add plussixonebanner
gg<-addBanner(gg)
```

![plot of chunk paths2](http://plussixoneblog.com/wp-content/uploads/2016/09/paths2-1-2.png)

Sydney's form over those years shows just how strong they have been for such a long time.  Apart from a dip towards the end of last year, which coincided with a slew of injuries and Buddy's well publicised time away from football, they have consistently hovered near the heights of traditional premiers. Their current rating is their highest in the last 3 years, while they haven't dropped below average (1500 points) in a long time - more than 6 years to be exact.

```r
dat %>%
        filter(Team == "Sydney" & ELO_post <= 1500) %>%
        arrange(desc(Game)) %>%
        select(Season, Round, Team, ELO_post) %>%
        head(5)

## # A tibble: 5 × 4
##   Season  Round   Team ELO_post
##    <dbl> <fctr>  <chr>    <dbl>
## 1   2010    R18 Sydney     1482
## 2   2010    R17 Sydney     1494
## 3   2010     R1 Sydney     1498
## 4   2009    R22 Sydney     1490
## 5   2009    R21 Sydney     1492
```

So, where are we now with these two teams? Clearly, Sydney is the higher rated team and is going to be a clear favourite in our system. Below is our rating system as it stands after the prelim, with the Bulldogs still sitting down in 7th spot!

![plot of chunk ratings](http://plussixoneblog.com/wp-content/uploads/2016/09/ratings-1-2.png)

Onto this weekend - before predicting this game, I wondered if Grand Finals were different beasts to normal games? My model is 'optimised' just across all games, with no changes for grand final matches. I haven't looked out historical Grand Final performance before. How do we go at predicting them specifically?

```r
# Only interested in the home team margin
dat_home <- dat %>%
        filter(TeamStatus == "Home")

gg <- ggplot(filter(dat_home, Round != "GF"), aes(x = PredMarg, y = Margin)) +
        geom_point(alpha = 0.6, color = "grey") +
        geom_point(data = filter(dat_home, Round == "GF"), alpha = 0.9, color = "#66999A") +
        theme_fivethirtyeight()

gg <- addBanner(gg)
```

![plot of chunk gf](http://plussixoneblog.com/wp-content/uploads/2016/09/gf-1-2.png)

Pretty good actually! We have correctly tipped more than 85% of Grand Finals, which is above our long-term average of 69%. We have a mean absolute prediction error (MAPE) of 22.6, which again is much better than our long-term MAPE of 26.8. We also clearly have less 'blowout' games in Grand Finals, likely due to the fact that we are more likely to have two 'relatively' event matched teams than in a normal game.

## Prediction

Finally - onto our all important prediction. How do we rate the chances for the weekend? Based on these ELO ratings, a team with that big a lead and a nominal home ground advantage[ref]I should really call this home team advantage[/ref], we expect Sydney to comfortably get up. Considering we have a pretty good record in tipping Grand Finals, I'd like to be pretty confident in that tip. But the Bulldogs are, if nothing else, a pretty tantalising story to follow. My head says follow the model, my heart barks like a Dog!

![round27](http://plussixoneblog.com/wp-content/uploads/2016/09/round27-1.png)
