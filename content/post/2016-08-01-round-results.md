---
title: Round 19 - AFL ELO Results
author: jamesday87
date: '2016-08-01'
categories:
  - AFL
  - Results
slug: round-results
---

I've now got around to doing a bit more analyses of my results each week and so have decided to split the AFL ELO model results and updated simulations into seperate posts. The simulation post will be out shortly! Round 19 saw our [ELO](http://plussixoneblog.com/2016/05/23/my-elo-rating-system-explained/) model do very well, as we expected from [our preview](http://plussixoneblog.com/2016/07/29/round-prediction/), with all teams favoured by our ELO model favoured by a significant margin. The only incorrect tip was the the upset win by Collingwood over West Coast, which our model attached a 41% probability to.

The round total of 8 out of 9 came with a mean absolute prediction error (MAPE) of 30.2. This gives us our AFL ELO model a season total of 117 out of 162 (72.2), with a MAPE of 29.2, just under our goal of 30!

##### RESULT PLOTS

The following two plots outline how the performance of these two metrics have tracked over the season.

![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/img/2016/08/unnamed-chunk-2-1.png)

![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/img/2016/08/unnamed-chunk-2-2.png)

Below I've plotted our expected margin against our actual margin. The line on the graph shows what we would expect if our model was perfect. I'll likely use this plot in the off-season to improve the model performance, but will continue to report it.
![plot of chunk unnamed-chunk-2](http://plussixoneblog.com/img/2016/08/unnamed-chunk-2-3.png)
