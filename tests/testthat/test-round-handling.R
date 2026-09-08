library(testthat)
library(here)
suppressMessages({
  library(dplyr)
  library(stringr)
  library(tibble)
  library(cli)
})

# The functions under test live in the weekly data process scripts. Sourcing
# them only defines functions - nothing here calls out to the AFL API.
source(here::here("scripts", "weekly_data_process", "1-get-data.R"))
source(here::here("scripts", "weekly_data_process", "5-finals_sims.R"))

# ── round types ──────────────────────────────────────────────────────────────

describe("is_finals_round()", {

  it("treats home and away rounds as regular", {
    expect_false(any(is_finals_round(c("Round 1", "Round 24", "Opening Round"))))
  })

  it("treats finals rounds as finals", {
    expect_true(all(is_finals_round(c("Finals Week 1", "Semi Finals",
                                      "Preliminary Finals", "Grand Final"))))
  })

  it("treats the wildcard round as finals however it is named", {
    expect_true(all(is_finals_round(c("Wildcard Round", "Wild Card Round",
                                      "wildcard round", "Wildcard Weekend"))))
  })

  it("returns FALSE rather than NA for a missing round name", {
    expect_identical(is_finals_round(NA_character_), FALSE)
  })

})

# ── round numbers ────────────────────────────────────────────────────────────

describe("patch_round_data_afl()", {

  # AFL Tables results as fitzRoy returns them - it doesn't know the wildcard
  # round, so those two games come back with no round number and are left
  # looking like home and away games
  results <- tibble(
    Game         = 1:5,
    Date         = as.Date(c("2026-08-22", "2026-08-29", "2026-08-29",
                             "2026-09-03", "2026-09-05")),
    Season       = 2026,
    Home.Team    = c("Melbourne", "Melbourne", "Adelaide", "Fremantle", "Sydney"),
    Away.Team    = c("Footscray", "Carlton", "Collingwood", "Hawthorn",
                     "Brisbane Lions"),
    Round.Number = c(24, NA, NA, 25, 25),
    Round.Type   = c("Regular", "Regular", "Regular", "Finals", "Finals"),
    Margin       = c(10, -5, 12, 30, 8)
  )

  results_afl <- results %>%
    mutate(Round.Number = c(24, 25, 25, 26, 26),
           Round.Type   = c("Regular", rep("Finals", 4))) %>%
    select(Date, Home.Team, Away.Team, Round.Number, Round.Type)

  it("keeps every game and every column", {
    patched <- patch_round_data_afl(results, results_afl)
    expect_equal(nrow(patched), nrow(results))
    expect_setequal(names(patched), names(results))
  })

  it("takes round numbers from AFL.com.au", {
    patched <- patch_round_data_afl(results, results_afl)
    expect_equal(patched$Round.Number, c(24, 25, 25, 26, 26))
  })

  it("marks the wildcard round as finals", {
    patched <- patch_round_data_afl(results, results_afl)
    expect_equal(patched$Round.Type, c("Regular", rep("Finals", 4)))
  })

  it("leaves the last home and away round as the last ladder round", {
    patched <- patch_round_data_afl(results, results_afl)
    regular <- patched %>% filter(Round.Type == "Regular", !is.na(Margin))
    expect_equal(max(regular$Round.Number), 24)
  })

  it("leaves games AFL.com.au doesn't have alone", {
    older <- tibble(Game = 1, Date = as.Date("1897-05-08"), Season = 1897,
                    Home.Team = "Carlton", Away.Team = "Geelong",
                    Round.Number = 1, Round.Type = "Regular", Margin = 5)
    patched <- patch_round_data_afl(older, results_afl)
    expect_equal(patched$Round.Number, 1)
    expect_equal(patched$Round.Type, "Regular")
  })

  it("does nothing without AFL.com.au results", {
    expect_identical(patch_round_data_afl(results, NULL), results)
    expect_identical(patch_round_data_afl(results, results_afl[0, ]), results)
  })

})

# ── completed finals ─────────────────────────────────────────────────────────

describe("prep_finals_results()", {

  ladder <- tibble(
    team.name = c("Fremantle", "Sydney", "Brisbane Lions", "Hawthorn", "Geelong",
                  "Adelaide", "Melbourne", "Collingwood", "Carlton",
                  "Port Adelaide"),
    position  = 1:10
  )

  # Wildcard round, then the qualifying and elimination finals
  finals_results <- tibble(
    Season    = 2026,
    Game      = 1:6,
    Round     = c(25, 25, 26, 26, 26, 26),
    Home.Team = c("Melbourne", "Collingwood", "Fremantle", "Sydney",
                  "Geelong", "Adelaide"),
    Away.Team = c("Port Adelaide", "Carlton", "Hawthorn", "Brisbane Lions",
                  "Collingwood", "Melbourne"),
    Margin    = c(12, -6, 25, 4, -9, 18)
  )

  it("attaches the home team's ladder position", {
    expect_equal(prep_finals_results(finals_results, ladder)$Rank,
                 c(7, 8, 1, 2, 5, 6))
  })

  it("counts the wildcard round as finals week one", {
    expect_equal(prep_finals_results(finals_results, ladder)$Finals_week,
                 c(1, 1, 2, 2, 2, 2))
  })

  it("flags wins from the margin", {
    expect_equal(prep_finals_results(finals_results, ladder)$Win,
                 c(1, 0, 1, 1, 0, 1))
  })

  it("gives every completed final a name", {
    prepped <- prep_finals_results(finals_results, ladder)
    expect_equal(get_wc_names(prepped$Rank[prepped$Finals_week == 1]),
                 c("WC1", "WC2"))
    expect_equal(get_wk2_names(prepped$Rank[prepped$Finals_week == 2]),
                 c("QF1", "QF2", "EF1", "EF2"))
  })

  it("returns NULL - simulate instead - when it can't place the games", {
    expect_null(prep_finals_results(finals_results, NULL))
    expect_null(prep_finals_results(NULL, ladder))
    expect_null(prep_finals_results(finals_results[0, ], ladder))
    expect_null(prep_finals_results(finals_results,
                                    ladder %>% filter(team.name != "Melbourne")))
  })

})
