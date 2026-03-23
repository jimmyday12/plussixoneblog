library(testthat)
library(here)

# Helper: detect off-season from a predictions data frame
.is_off_season <- function(preds) {
  pred_dates <- as.Date(preds$Date)
  as.numeric(Sys.Date() - max(pred_dates)) > 120
}

# ── current_elo.csv ──────────────────────────────────────────────────────────

describe("current_elo.csv", {

  elo_path <- here::here("data_files", "raw-data", "current_elo.csv")

  it("file exists", {
    expect_true(file.exists(elo_path))
  })

  it("has exactly 18 teams", {
    elo <- read.csv(elo_path)
    expect_equal(nrow(elo), 18)
  })

  it("has required columns", {
    elo <- read.csv(elo_path)
    required_cols <- c("Team", "Date", "Game", "Season", "Round",
                       "ELO", "ELO_pre", "ELO_change", "Updated")
    expect_true(all(required_cols %in% names(elo)))
  })

  it("contains all 18 AFL teams", {
    elo <- read.csv(elo_path)
    known_teams <- c(
      "Adelaide", "Brisbane Lions", "Carlton", "Collingwood",
      "Essendon", "Fremantle", "Geelong", "Gold Coast", "GWS",
      "Hawthorn", "Melbourne", "North Melbourne", "Port Adelaide",
      "Richmond", "St Kilda", "Sydney", "West Coast", "Footscray"
    )
    missing <- setdiff(known_teams, elo$Team)
    expect_true(
      length(missing) == 0,
      label = paste0("Missing teams: ", paste(missing, collapse = ", "))
    )
  })

  it("ELO values are in a reasonable range (1200-1800)", {
    elo <- read.csv(elo_path)
    expect_true(all(elo$ELO >= 1200 & elo$ELO <= 1800))
    expect_true(all(elo$ELO_pre >= 1200 & elo$ELO_pre <= 1800))
  })

  it("no duplicate team names", {
    elo <- read.csv(elo_path)
    expect_equal(length(unique(elo$Team)), nrow(elo))
  })

  it("Updated timestamp was set within the last 24 hours", {
    elo <- read.csv(elo_path)
    updated_time <- as.POSIXct(elo$Updated[1], format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    now_utc <- as.POSIXct(Sys.time(), tz = "UTC")
    age_hours <- as.numeric(difftime(now_utc, updated_time, units = "hours"))
    expect_true(
      age_hours >= 0 && age_hours <= 24,
      label = paste0("Updated timestamp is ", round(age_hours, 1), " hours old (expected <= 24)")
    )
  })

})

# ── AFLM_results.csv ─────────────────────────────────────────────────────────

describe("AFLM_results.csv", {

  results_path <- here::here("data_files", "processed-data", "AFLM_results.csv")

  it("file exists", {
    expect_true(file.exists(results_path))
  })

  it("has more than 10,000 rows", {
    results <- read.csv(results_path)
    expect_gt(nrow(results), 10000)
  })

  it("has required columns", {
    results <- read.csv(results_path)
    required_cols <- c("Game", "Date", "Season", "Home.Team", "Away.Team",
                       "Home.Points", "Away.Points", "Margin",
                       "Home.ELO_pre", "Away.ELO_pre",
                       "Home.ELO", "Away.ELO",
                       "Probability", "Prediction")
    missing <- setdiff(required_cols, names(results))
    expect_true(
      length(missing) == 0,
      label = paste0("Missing columns: ", paste(missing, collapse = ", "))
    )
  })

  it("no duplicate Game IDs", {
    results <- read.csv(results_path)
    expect_equal(length(unique(results$Game)), nrow(results))
  })

  it("ELO values are in a reasonable range (1200-1800)", {
    results <- read.csv(results_path)
    expect_true(all(results$Home.ELO >= 1200 & results$Home.ELO <= 1800))
    expect_true(all(results$Away.ELO >= 1200 & results$Away.ELO <= 1800))
    expect_true(all(results$Home.ELO_pre >= 1200 & results$Home.ELO_pre <= 1800))
    expect_true(all(results$Away.ELO_pre >= 1200 & results$Away.ELO_pre <= 1800))
  })

  it("Probability values are between 0 and 1", {
    results <- read.csv(results_path)
    expect_true(all(results$Probability >= 0 & results$Probability <= 1))
  })

  it("Season column contains plausible AFL years (1897 to current year)", {
    results <- read.csv(results_path)
    current_year <- as.integer(format(Sys.Date(), "%Y"))
    expect_true(all(results$Season >= 1897 & results$Season <= current_year))
  })

  it("has results for the current season", {
    results <- read.csv(results_path)
    current_year <- as.integer(format(Sys.Date(), "%Y"))
    expect_true(any(results$Season == current_year))
  })

})

# ── AFLM_predictions.csv ─────────────────────────────────────────────────────

describe("AFLM_predictions.csv", {

  pred_path <- here::here("data_files", "processed-data", "AFLM_predictions.csv")

  it("file exists", {
    expect_true(file.exists(pred_path))
  })

  it("has required columns", {
    preds <- read.csv(pred_path)
    required_cols <- c("Season", "Game", "Date", "Day", "Time",
                       "Round.Number", "Venue", "Home.Team", "Away.Team",
                       "Prediction", "Probability", "Result")
    missing <- setdiff(required_cols, names(preds))
    expect_true(
      length(missing) == 0,
      label = paste0("Missing columns: ", paste(missing, collapse = ", "))
    )
  })

  it("has rows when season is active", {
    preds <- read.csv(pred_path)
    if (.is_off_season(preds)) skip("Off-season: predictions are from a prior season")
    expect_gt(nrow(preds), 0)
  })

  it("Probability values are between 0 and 1", {
    preds <- read.csv(pred_path)
    if (.is_off_season(preds)) skip("Off-season")
    expect_true(all(preds$Probability >= 0 & preds$Probability <= 1))
  })

  it("Prediction margins are in a plausible AFL range (-100 to 100)", {
    preds <- read.csv(pred_path)
    if (.is_off_season(preds)) skip("Off-season")
    expect_true(all(preds$Prediction >= -100 & preds$Prediction <= 100))
  })

  it("prediction dates include future games", {
    preds <- read.csv(pred_path)
    if (.is_off_season(preds)) skip("Off-season")
    expect_true(any(as.Date(preds$Date) >= Sys.Date()))
  })

  it("Season values are the current year", {
    preds <- read.csv(pred_path)
    if (.is_off_season(preds)) skip("Off-season")
    current_year <- as.integer(format(Sys.Date(), "%Y"))
    expect_true(all(preds$Season == current_year))
  })

})

# ── predictions.csv (raw-data mirror) ────────────────────────────────────────

describe("predictions.csv (raw-data mirror)", {

  raw_pred_path <- here::here("data_files", "raw-data", "predictions.csv")
  proc_pred_path <- here::here("data_files", "processed-data", "AFLM_predictions.csv")

  it("file exists", {
    expect_true(file.exists(raw_pred_path))
  })

  it("row count matches AFLM_predictions.csv", {
    preds_proc <- read.csv(proc_pred_path)
    if (.is_off_season(preds_proc)) skip("Off-season")
    preds_raw <- read.csv(raw_pred_path)
    expect_equal(nrow(preds_raw), nrow(preds_proc))
  })

  it("Game IDs match AFLM_predictions.csv", {
    preds_proc <- read.csv(proc_pred_path)
    if (.is_off_season(preds_proc)) skip("Off-season")
    preds_raw <- read.csv(raw_pred_path)
    expect_equal(preds_raw$Game, preds_proc$Game)
  })

})
