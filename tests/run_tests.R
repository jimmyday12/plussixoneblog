library(testthat)
library(here)

results <- test_dir(here::here("tests", "testthat"), reporter = "progress")

if (!all_passed(results)) {
  quit(status = 1)
}
