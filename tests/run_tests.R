library(testthat)
library(here)

test_dir(here::here("tests", "testthat"), reporter = "progress", stop_on_failure = TRUE)
