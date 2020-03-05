---
title: Ratings and Simulations
author: James Day
date: '2018-03-27'
slug: aflm-ratings-and-simulations
categories:
  - AFLM
  - Simulation
tags: []
output: 
  html_document:
    keep_md: TRUE
    self_contained: TRUE

---

Welcome to our all new AFL Men's ratings and tips page! Here you will the latest ratings, tips for the upcoming rounds and any simulations that have been done. I'll usually aim to update these early in the week to give you time to digest Any questions, let me know on Twitter!

Last updated: 2020-03-05.





## Summary
Below are the updated AFL Men's ratings and simulations. These are based off our ELO model and simulations. 



<!--html_preserve--><div id="htmlwidget-9eb9070183030ebee01e" style="width:95%;height:700px;" class="widgetframe html-widget"></div>
<script type="application/json" data-for="htmlwidget-9eb9070183030ebee01e">{"x":{"url":"aflm-ratings-and-simulations_files/figure-html//widgets/widget_formattable.html","options":{"xdomain":"*","allowfullscreen":false,"lazyload":false}},"evals":[],"jsHooks":[]}</script><!--/html_preserve-->

And below you can see the change in ratings for each team. 

![](aflm-ratings-and-simulations_files/figure-html/ratings-plot-1.png)<!-- -->

# Simulations
In order to get our Top 8, Top 4 and Top 1 probabilities, we simulate the season 50 000 times. This has been optimised considerably this year (code to come) which is nice. 

Firstly, we have each team's chance of making finals displayed across the season. 

![](aflm-ratings-and-simulations_files/figure-html/sims-teams-1.png)<!-- -->

The following plot shows a ridgegraph of the number of wins of each team in those simulations. 

![](aflm-ratings-and-simulations_files/figure-html/sims-plot-1.png)<!-- -->

And below we show the probability of each team finishing at each ladder position in a heatmap. 


![](aflm-ratings-and-simulations_files/figure-html/sim_plotr-1.png)<!-- -->




