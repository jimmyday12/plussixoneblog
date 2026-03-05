# tune_new_elo.R
#
# Tuning script for new_elo_model.R — 5 parameter version.
# Run once manually, not part of the weekly pipeline.
#
# Parameters being tuned:
#   v             - venue familiarity (log ratio)
#   base_k        - learning rate
#   carryOver     - offseason regression
#   finals_k_mult - finals update weight (expected near 0)
#   B             - sigmoid steepness (tuned separately in 1D search)
#
# Temporal split:
#   Train from: 1990 (national competition era)
#   Burn-in:    1990-1996
#   Evaluate:   1997-present

library(tidyverse)
library(here)

source(here("scripts", "weekly_data_process", "0-functions.R"))
source(here("scripts", "weekly_data_process", "2-elo_prep.R"))
source(here("scripts", "weekly_data_process", "new_elo_model.R"))

# ── Load and prepare data ─────────────────────────────────────────────────────

aflm    <- read_rds(here("data_files", "raw-data", "AFLM.rds"))
results <- aflm$results

results_train <- results %>%
  filter(Season >= 1990, !is.na(Home.Points))

results_eval <- results_train %>%
  filter(Season >= 1997)

eval_idx <- which(results_train$Season >= 1997)

cat(sprintf("Training games: %d  |  Eval games: %d  |  Eval seasons: %d-%d\n\n",
            nrow(results_train), nrow(results_eval),
            min(results_eval$Season), max(results_eval$Season)))

actual_binary <- ifelse(
  results_eval$Home.Points > results_eval$Away.Points, 1,
  ifelse(results_eval$Home.Points < results_eval$Away.Points, 0, 0.5)
)
actual_margin <- results_eval$Home.Points - results_eval$Away.Points

# ── Scoring function ──────────────────────────────────────────────────────────
# params_vec: c(v, base_k, carryOver, finals_k_mult)
# B passed separately for clean 1D search

score_model <- function(params_vec, B) {
  
  params <- list(
    v             = params_vec[1],
    base_k        = params_vec[2],
    carryOver     = params_vec[3],
    finals_k_mult = params_vec[4],
    B             = B
  )
  
  tryCatch({
    model      <- run_new_elo(results_train, params, use_margin = FALSE)
    eval_preds <- model$results$Probability[eval_idx]
    
    brier <- mean((eval_preds - actual_binary)^2)
    mae   <- mean(abs(model$results$Prediction[eval_idx] - actual_margin))
    
    list(brier = brier, mae = mae)
    
  }, error = function(e) list(brier = 1, mae = 999))
}

brier_only <- function(params_vec, B) score_model(params_vec, B)$brier

# ── Bounds ────────────────────────────────────────────────────────────────────
# finals_k_mult upper bound 1.5 — no reason finals should update more than 3-season games

lower_bounds <- c(v = 0,   base_k = 2,  carryOver = 0.30, finals_k_mult = 0.0)
upper_bounds <- c(v = 10,  base_k = 60, carryOver = 0.95, finals_k_mult = 1.5)

FIXED_B <- 0.04

# ── Baseline ──────────────────────────────────────────────────────────────────

cat("── Baseline ────────────────────────────────────────────────────────────\n")
baseline_params <- c(v = 1.186, base_k = 6.721, carryOver = 0.623, finals_k_mult = 0)
baseline        <- score_model(baseline_params, B = FIXED_B)
cat(sprintf("Brier: %.5f  |  MAE: %.2f pts\n\n", baseline$brier, baseline$mae))

# ── Optimise ──────────────────────────────────────────────────────────────────

cat("── L-BFGS-B optimisation (5 starting points) ───────────────────────────\n")

starting_points <- list(
  baseline_params,
  c(v = 2.0,  base_k = 10,  carryOver = 0.65, finals_k_mult = 0.0),
  c(v = 0.5,  base_k = 5,   carryOver = 0.75, finals_k_mult = 0.2),
  c(v = 3.0,  base_k = 15,  carryOver = 0.80, finals_k_mult = 0.5),
  c(v = 1.5,  base_k = 8,   carryOver = 0.55, finals_k_mult = 0.1)
)

optim_results <- starting_points %>%
  imap_dfr(function(start, i) {
    cat(sprintf("  Starting point %d/%d\n", i, length(starting_points)))
    
    result <- optim(
      par     = start,
      fn      = brier_only,
      B       = FIXED_B,
      method  = "L-BFGS-B",
      lower   = lower_bounds,
      upper   = upper_bounds,
      control = list(maxit = 1000, factr = 1e6)
    )
    
    final <- score_model(result$par, B = FIXED_B)
    
    tibble(
      start         = i,
      v             = result$par[1],
      base_k        = result$par[2],
      carryOver     = result$par[3],
      finals_k_mult = result$par[4],
      Brier         = final$brier,
      MAE           = final$mae,
      convergence   = result$convergence
    )
  }) %>%
  arrange(Brier)

cat("\n── Optimisation results:\n")
print(optim_results)

# Check for boundary hits
best <- optim_results %>% slice(1)
# Replace the boundary check block with this:
cat("\n── Boundary check:\n")
for (nm in names(params_check)) {
  val <- unname(params_check[nm])
  lb  <- unname(lower_bounds[nm])
  ub  <- unname(upper_bounds[nm])
  if (abs(val - lb) < 0.01)      cat(sprintf("  ⚠ %s = %.3f is AT lower bound (%.2f)\n", nm, val, lb))
  else if (abs(val - ub) < 0.01) cat(sprintf("  ⚠ %s = %.3f is AT upper bound (%.2f)\n", nm, val, ub))
  else                            cat(sprintf("  ✓ %s = %.3f  [%.2f, %.2f]\n", nm, val, lb, ub))
}

# ── 1D search over B ─────────────────────────────────────────────────────────

cat("\n── 1D search over B ────────────────────────────────────────────────────\n")

best_par_vec <- c(v = best$v, base_k = best$base_k,
                  carryOver = best$carryOver, finals_k_mult = best$finals_k_mult)

b_results <- tibble(B = seq(0.025, 0.08, by = 0.005)) %>%
  mutate(
    scores = map(B, ~score_model(best_par_vec, B = .x)),
    Brier  = map_dbl(scores, "brier"),
    MAE    = map_dbl(scores, "mae")
  ) %>%
  select(-scores)

print(b_results)

best_B       <- b_results %>% slice(which.min(Brier)) %>% pull(B)
final_scores <- score_model(best_par_vec, B = best_B)

cat(sprintf("\nBest B: %.3f\n", best_B))

# ── Summary ───────────────────────────────────────────────────────────────────

improvement <- (baseline$brier - final_scores$brier) / baseline$brier * 100

cat(sprintf("
════════════════════════════════════════════════════════════════════════
 FINAL SUMMARY
════════════════════════════════════════════════════════════════════════

                     Brier     Margin MAE
 Baseline:           %.5f   %.2f pts
 Optimised (B=0.04): %.5f   %.2f pts
 Optimised (best B): %.5f   %.2f pts

 Improvement:        %.1f%% Brier

 Recommended parameters:
   v             <- %.4f
   base_k        <- %.4f
   carryOver     <- %.4f
   finals_k_mult <- %.4f
   B             <- %.4f
════════════════════════════════════════════════════════════════════════\n",
            baseline$brier,     baseline$mae,
            best$Brier,         best$MAE,
            final_scores$brier, final_scores$mae,
            improvement,
            best$v, best$base_k, best$carryOver, best$finals_k_mult, best_B
))

# ── Save ──────────────────────────────────────────────────────────────────────

write_rds(
  list(
    baseline      = baseline,
    optim_results = optim_results,
    b_results     = b_results,
    best_params   = c(best_par_vec, B = best_B)
  ),
  here("data_files", "raw-data", "elo_tuning_results.rds")
)

cat("Saved to data_files/raw-data/elo_tuning_results.rds\n")