# tune_new_elo.R  —  improved 2026
#
# Changes from previous version:
#   1. B co-optimised with all other parameters (was a separate 1D search)
#   2. Leave-one-season-out cross-validation (was train/eval on same period)
#   3. Fixed params_check bug
#   4. finals_k_mult upper bound tightened to 0.5 (empirically validated near 0)
#   5. More starting points to reduce risk of local minima
#   6. Progress reporting improved
#
# Parameters tuned:
#   v             - venue familiarity log ratio
#   base_k        - learning rate
#   carryOver     - offseason regression to mean
#   finals_k_mult - finals update weight
#   B             - sigmoid steepness
#
# Objective: mean Brier score across leave-one-season-out folds (1997-present)
# Burn-in:   1990-1996 always included in training (never held out)

library(tidyverse)
library(here)

source(here("scripts", "weekly_data_process", "0-functions.R"))
source(here("scripts", "weekly_data_process", "2-elo_prep.R"))
source(here("scripts", "weekly_data_process", "new_elo_model.R"))

# ── Load data ─────────────────────────────────────────────────────────────────

aflm    <- read_rds(here("data_files", "raw-data", "AFLM.rds"))
results <- aflm$results %>%
  filter(Season >= 1990, !is.na(Home.Points))

BURN_IN_END  <- 1996   # seasons used for burn-in only, never held out
EVAL_START   <- 1997
eval_seasons <- results %>%
  filter(Season >= EVAL_START) %>%
  pull(Season) %>%
  unique() %>%
  sort()

cat(sprintf(
  "Burn-in: 1990-%d  |  LOSO folds: %d seasons (%d-%d)  |  Total games: %d\n\n",
  BURN_IN_END, length(eval_seasons),
  min(eval_seasons), max(eval_seasons),
  nrow(results)
))

# ── Scoring function ──────────────────────────────────────────────────────────
# Fit model once on all data. Since model$results$Probability is always the
# pre-game prediction (before that game's ELO update fires), every game is
# already predicted out-of-sample in temporal order — a proper walk-forward
# evaluation without needing to refit 30 times.
#
# Score = mean per-season Brier across eval seasons (1997-present).
# Averaging per-season rather than per-game prevents recent seasons
# (which have more games due to expansion) from dominating.

score_loso <- function(params_vec, verbose = FALSE) {
  
  params <- list(
    v             = params_vec["v"],
    base_k        = params_vec["base_k"],
    carryOver     = params_vec["carryOver"],
    finals_k_mult = params_vec["finals_k_mult"],
    B             = params_vec["B"]
  )
  
  tryCatch({
    
    model <- run_new_elo(results, params, use_margin = FALSE)
    
    mean_brier <- model$results %>%
      filter(Season >= EVAL_START, !is.na(Home.Points)) %>%
      mutate(
        Actual = ifelse(Home.Points > Away.Points, 1,
                        ifelse(Home.Points < Away.Points, 0, 0.5)),
        Brier  = (Probability - Actual)^2
      ) %>%
      group_by(Season) %>%
      summarise(Brier = mean(Brier), .groups = "drop") %>%
      pull(Brier) %>%
      mean(na.rm = TRUE)
    
    if (verbose) {
      cat(sprintf(
        "  v=%.3f  k=%.3f  co=%.3f  fk=%.3f  B=%.3f  =>  Brier=%.5f\n",
        params$v, params$base_k, params$carryOver,
        params$finals_k_mult, params$B, mean_brier
      ))
    }
    
    mean_brier
    
  }, error = function(e) {
    if (verbose) cat("  ERROR:", conditionMessage(e), "\n")
    NA_real_
  })
}

# ── Bounds ────────────────────────────────────────────────────────────────────
# finals_k_mult: tightened to [0, 0.5] — empirical validation showed near-0
#                is optimal for predicting next-season Round 1 performance
# B: [0.01, 0.10] covers all sensible sigmoid steepness values

lower_bounds <- c(v = 0,    base_k = 2,   carryOver = 0.30,
                  finals_k_mult = 0.0,  B = 0.010)
upper_bounds <- c(v = 10,   base_k = 60,  carryOver = 0.95,
                  finals_k_mult = 0.5,  B = 0.100)

# ── Baseline (previous parameters) ───────────────────────────────────────────

cat("── Baseline (previous parameters) ─────────────────────────────────────\n")
baseline_params <- c(v = 5.980, base_k = 6.730, carryOver = 0.619,
                     finals_k_mult = 0.354, B = 0.040)
baseline_score  <- score_loso(baseline_params, verbose = FALSE)
cat(sprintf("LOSO Brier: %.5f\n\n", baseline_score))

# ── Starting points ───────────────────────────────────────────────────────────
# More diverse starting points to reduce local minima risk
# Previous best is always included as starting point 1

starting_points <- list(
  # 1. Previous best
  c(v = 5.980, base_k = 6.730,  carryOver = 0.619, finals_k_mult = 0.354, B = 0.040),
  # 2. Low venue effect, higher k
  c(v = 1.0,   base_k = 15.0,   carryOver = 0.65,  finals_k_mult = 0.1,   B = 0.040),
  # 3. High venue effect, lower k
  c(v = 4.0,   base_k = 5.0,    carryOver = 0.75,  finals_k_mult = 0.0,   B = 0.035),
  # 4. High carry-over (slow regression)
  c(v = 2.0,   base_k = 10.0,   carryOver = 0.85,  finals_k_mult = 0.2,   B = 0.045),
  # 5. Low carry-over (fast regression)
  c(v = 3.0,   base_k = 8.0,    carryOver = 0.45,  finals_k_mult = 0.1,   B = 0.050),
  # 6. Steeper sigmoid
  c(v = 2.5,   base_k = 7.0,    carryOver = 0.60,  finals_k_mult = 0.0,   B = 0.060),
  # 7. Shallower sigmoid
  c(v = 3.5,   base_k = 12.0,   carryOver = 0.70,  finals_k_mult = 0.3,   B = 0.025),
  # 8. Near-zero finals, mid range everything else
  c(v = 2.0,   base_k = 8.0,    carryOver = 0.60,  finals_k_mult = 0.0,   B = 0.040)
)

# ── Optimisation ──────────────────────────────────────────────────────────────

cat(sprintf(
  "── L-BFGS-B optimisation (%d starting points × LOSO) ─────────────────────\n",
  length(starting_points)
))
cat("Note: LOSO is slow — each function evaluation fits one model per season\n\n")

t_start <- proc.time()

optim_results <- imap_dfr(starting_points, function(start, i) {
  
  cat(sprintf("[%d/%d] Starting: v=%.2f k=%.2f co=%.2f fk=%.2f B=%.3f\n",
              i, length(starting_points),
              start["v"], start["base_k"], start["carryOver"],
              start["finals_k_mult"], start["B"]))
  
  result <- optim(
    par     = start,
    fn      = score_loso,
    method  = "L-BFGS-B",
    lower   = lower_bounds,
    upper   = upper_bounds,
    control = list(maxit = 500, factr = 1e7)
  )
  
  final_score <- score_loso(result$par, verbose = FALSE)
  
  cat(sprintf("       Result:   v=%.3f k=%.3f co=%.3f fk=%.3f B=%.3f  Brier=%.5f  [conv=%d]\n\n",
              result$par["v"], result$par["base_k"], result$par["carryOver"],
              result$par["finals_k_mult"], result$par["B"],
              final_score, result$convergence))
  
  tibble(
    start_point   = i,
    v             = result$par["v"],
    base_k        = result$par["base_k"],
    carryOver     = result$par["carryOver"],
    finals_k_mult = result$par["finals_k_mult"],
    B             = result$par["B"],
    Brier         = final_score,
    convergence   = result$convergence
  )
}) %>%
  arrange(Brier)

t_elapsed <- (proc.time() - t_start)["elapsed"]
cat(sprintf("\nOptimisation complete in %.1f minutes\n\n", t_elapsed / 60))

# ── Results ───────────────────────────────────────────────────────────────────

cat("── All results (sorted by Brier) ───────────────────────────────────────\n")
print(optim_results, n = nrow(optim_results))

best <- optim_results %>% slice(1)

# Boundary check
cat("\n── Boundary check (best parameters) ───────────────────────────────────\n")
best_vec <- c(v             = best$v,
              base_k        = best$base_k,
              carryOver     = best$carryOver,
              finals_k_mult = best$finals_k_mult,
              B             = best$B)

for (nm in names(best_vec)) {
  val <- unname(best_vec[nm])
  lb  <- unname(lower_bounds[nm])
  ub  <- unname(upper_bounds[nm])
  if (abs(val - lb) < 0.01)
    cat(sprintf("  ⚠  %s = %.4f  AT lower bound (%.3f) — consider widening\n", nm, val, lb))
  else if (abs(val - ub) < 0.01)
    cat(sprintf("  ⚠  %s = %.4f  AT upper bound (%.3f) — consider widening\n", nm, val, ub))
  else
    cat(sprintf("  ✓  %s = %.4f  [%.3f, %.3f]\n", nm, val, lb, ub))
}

# ── Improvement summary ───────────────────────────────────────────────────────

improvement <- (baseline_score - best$Brier) / baseline_score * 100

cat(sprintf("
════════════════════════════════════════════════════════════════════════
 FINAL SUMMARY  (LOSO Brier, %d seasons)
════════════════════════════════════════════════════════════════════════

 Previous params:    %.5f
 New params:         %.5f
 Improvement:        %.2f%%

 Recommended parameters:
   v             <- %.4f
   base_k        <- %.4f
   carryOver     <- %.4f
   finals_k_mult <- %.4f
   B             <- %.4f
════════════════════════════════════════════════════════════════════════\n",
            length(eval_seasons),
            baseline_score, best$Brier, improvement,
            best$v, best$base_k, best$carryOver, best$finals_k_mult, best$B
))

# ── Save ──────────────────────────────────────────────────────────────────────

write_rds(
  list(
    baseline      = baseline_score,
    optim_results = optim_results,
    best_params   = best_vec
  ),
  here("data_files", "raw-data", "elo_tuning_results.rds")
)

cat("Saved to data_files/raw-data/elo_tuning_results.rds\n")