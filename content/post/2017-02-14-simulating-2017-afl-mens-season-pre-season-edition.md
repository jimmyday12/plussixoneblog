---
title: 'Simulating the 2017 AFL Mens season: Pre-season edition!'
author: jamesday87
date: '2017-02-15'
categories:
  - Simulation
slug: simulating-2017-afl-mens-season-pre-season-edition
---

As I've indicated previously, I've finally cleared some time to get back into blogging! Sparked largely by a tweet from the fantastic [The Arc](http://thearcfooty.com) blog, I've got some very preliminary season simulations together.

<!-- more -->

The competition proposed by [The Arc](http://thearcfooty.com) is simple - put forward your probabilities of each team making the finals for 2017.

<blockquote>

>
> Think you can do a better job of predicting the finalists than our Elo model? Go on then! <https://t.co/YA3qAhwpPB>
>
>
— The Arc (@TheArcFooty) [January 21, 2017](https://twitter.com/TheArcFooty/status/822735709731573761)</blockquote>

While this is not uncommon in [footy punditry](http://www.afl.com.au/news/2016-03-24/crystal-ball-predictions-for-2016), attaching probabilities to those predications is. Compared to a dichotomous Finals/No Finals answer, probabilistic forecasting gives an [estimate of how confident we are in the outcome.](http://www.nssl.noaa.gov/users/brooks/public_html/prob/Probability.html)

### Pre-Season ratings

For those who are new to the site, last year we introduced our ELO rating system. As per last year, I'll be using our ELO ratings to post weekly predictions of each match. I'll also simulate the remainder of the season as the year goes on to estimate probabilities of certain finishing positions. Please read the links below to understand this process

[ELO Rating system](http://plussixoneblog.com/elo-rating-system/) | [Simulating the season](http://plussixoneblog.com/2016/05/12/simulating-the-season/)

Let's look at our current ratings of each team heading into 2017. As a reminder, we regress each teams rating back towards the mean at the end of the year. Accordingly, these ratings are slightly different to the [end of season ratings](http://plussixoneblog.com/2016/09/29/grand-final-preview4/) in that they are more 'condense'.

![plot of chunk Ratings](http://plussixoneblog.com/img/2017/02/Ratings-1-6.png)

To summarise some trends that we can see (and what we saw towards the end of last year).

  * Sydney remain as the lone ratings "leader", slightly ahead of GWS, Adelaide and Geelong

  * A pack of followers is clumped after this group in Hawthorn, the Eagles and reigning premiers The Bulldogs

  * After this a relatively large drop-off occurs to our 'average' teams (North, Port, Collingwood, Melbourne and Saints)

  * A gradual decline followed through the remainder of the bottom 8

  * The bottom 2 in Brisbane and Essendon remain pretty bad

Of course, one thing to note about our ELO ratings at the start of the year is that they are very naive. Regressing to the mean attempts to somewhat account for player movement, the draft, free agency and general player development which _should_ lead to equalisation[ref]I've got a loose idea of how I might look at this. In the pipeline![/ref].

My model however doesn't understand some of the nuances in these factors. ELO is ignorant, for example to the fact that Hawthorn lost [571 games of experience](http://indaily.com.au/sport/football/2016/10/19/clarko-defends-tough-decisions-as-hawks-look-to-the-future/). Or that the Bombers will welcome back [9 suspended players](http://www.heraldsun.com.au/sport/afl/teams/essendon/banned-essendon-players-allowed-to-return-to-the-club-in-training-capacity/news-story/bdc48dc745079415d2836e9551efe7bc). Nonetheless, given many [well-known human biases in predicting outcomes](http://www.espn.com.au/chalk/story/_/id/11863567/betting-five-biggest-cognitive-biases-impair-sports-bettors-most), perhaps ignorance is bliss?

### Simulations

We could simply take our ratings and assume that this would be the order of our predicted ladder at the end of the year. However, we wouldn't be taking into account the [AFL's uneven fixture](http://footymaths.blogspot.com.au/p/we-have-posted-before-on-this-blog.html). The AFL attempts to give harder teams a more difficult draw and easier teams a harder draw. I'll review the fixture in detail in a later post before the season starts.

As per our methodology, we can take this years fixture and simulate each result based on the respective ELO ratings of each team. Repeat that 10 000 times and we get some estimates for various finishing positions!

![plot of chunk Simulation](http://plussixoneblog.com/img/2017/02/Simulation-1-6.png)

An obvious take-away from the heat map is the massive spread of each team's finishing position. With the exception of Sydney at the top and the Lions and Bombers at the bottom, no team finishes in a single position in more than 13% of simulations. In fact, the only position where a team doesn't finish at least once is the Lions finishing 1st. Every other team finishes in each position in at least 1 simulation!

Nonetheless, we can also see that the 'better' teams, at least according to our ELO model, tend to finish towards the top and the 'worse' teams towards the bottom, which is what we'd expect. This large spread, with a general trend, is also apparent in the density plots for each team. It's a little hard to fit all teams on one graph but you can see the spread of finishing positions for each team, peaking around their median result.

![plot of chunk distribution](http://plussixoneblog.com/img/2017/02/distribution-1-6.png)

### Finals Probabilities

Lastly, we can use our probabilities of finishing positions to also estimate large groupings. This finally gives us, among other things, an answer to [The Arc](http://thearcfooty.com) original question. Sydney remains the favourite, while perhaps the most surprising is the reigning premiers only making finals in 54% of simulations!

I've submitted these to [The Arc](http://thearcfooty.com) - wish me luck!

![prob table](http://plussixoneblog.com/img/2017/02/roundPred.png)
