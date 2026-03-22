# plussixoneblog — data pipeline

[![Update data](https://github.com/jimmyday12/plussixoneblog/actions/workflows/data_process.yaml/badge.svg)](https://github.com/jimmyday12/plussixoneblog/actions/workflows/data_process.yaml)

This repo runs an automated AFL data pipeline and stores the output files used by [plussixoneblog.com](https://www.plussixoneblog.com).

The website itself lives in a separate repo: [jimmyday12/plussixone_quarto](https://github.com/jimmyday12/plussixone_quarto).

---

## What it does

GitHub Actions run R scripts to:

1. **Fetch AFL fixture and results** via [fitzRoy](https://github.com/jimmyday12/fitzRoy)
2. **Run an ELO rating model** to generate team ratings and game predictions
3. **Simulate the season** (10,000 iterations) to produce ladder finish probabilities
4. **Commit updated data files** back to this repo so the Quarto site can read them

The pipeline runs Thursday–Monday at 5am, 8am, 11am, and 2pm UTC (catching new results as they come in over the weekend).

A separate workflow runs weekly on Wednesday to submit tips to the [Monash Probabilistic Tipping](https://probabilistic-footy.monash.edu) competition.

---

## Active scripts

| Script | Purpose |
|---|---|
| `scripts/weekly_data_process/weekly_data_process.R` | Main orchestrator — sources all pipeline steps |
| `scripts/weekly_data_process/1-get-data.R` | Fetches fixture and results via fitzRoy |
| `scripts/weekly_data_process/2-elo_prep.R` | Prepares data for the ELO model |
| `scripts/weekly_data_process/3-elo-run.R` | Runs ELO ratings |
| `scripts/weekly_data_process/4-sims.R` | Season simulations |
| `scripts/weekly_data_process/5-finals_sims.R` | Finals series simulations |
| `scripts/weekly_monash_tips.R` | Submits weekly tips to Monash Polytip |
| `scripts/tuning_elos.R` | ELO parameter tuning experiments |

---

## Output files

All outputs are written to `data_files/processed-data/`:

| File | Contents |
|---|---|
| `AFLM_elo.csv` | Current ELO ratings for all teams |
| `AFLM_predictions.csv` | Predictions for upcoming games |
| `AFLM_predictions_history_2026.csv` | Historical predictions for the current season |
| `AFLM_results.csv` | Game results |
| `AFLM_sims_combined.csv` | Ladder finish probabilities from simulations |
| `AFLM_sims_history.csv` | Historical simulation results |
| `AFLM_home_away_ongoing.csv` | Home/away advantage adjustments |

Raw data fetched from external sources is cached in `data_files/raw-data/`.

---

## GitHub Actions

| Workflow | Schedule | Purpose |
|---|---|---|
| `data_process.yaml` | Thu–Mon, 4× daily | Fetch data, run model, commit outputs |
| `weekly-monash-tips.yaml` | Wednesday midnight UTC | Submit Monash tips |
