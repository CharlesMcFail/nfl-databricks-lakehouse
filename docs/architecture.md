# Architecture (Databricks Lakehouse + Medallion)

This project is organized using a classic medallion architecture inside Unity Catalog:

- Bronze = raw truth (minimal changes)
- Silver = trusted clean tables (typed + deduped + validated)
- Gold = features, models, and chart-ready views (business outputs)

The NFL matchup is the attention hook; the architecture is the main technical demonstration.

---

## Unity Catalog Layout

Catalog: `workspace`

Schemas:
- `workspace.nfl_bronze`
- `workspace.nfl_silver`
- `workspace.nfl_gold`

This structure makes it obvious:
- where raw data lives
- where cleaned tables live
- where model outputs live

---

## Data Flow Overview

### Bronze → Silver (Trust Layer)
Goal: convert raw CSV tables into reliable, typed, deduplicated datasets.

Common Silver steps:
- enforce data types (dates, ints, doubles)
- remove duplicates (e.g., 1 row per `game_id` tables)
- basic null handling
- sanity checks (impossible values, duplicate keys)

Silver tables used in this project:
- `workspace.nfl_silver.games_2025`
- `workspace.nfl_silver.market_odds_2025`
- `workspace.nfl_silver.team_game_basic_2025`
- `workspace.nfl_silver.weather_2025`

---

### Silver → Gold (Business / Analytics Layer)
Goal: build reusable analytics features and final outputs (probabilities + rankings + charts).

Gold tables/views in this project:
- `team_power_v2_2025` (baseline + recent form → power score)
- `team_spread_rating_v2` (power → spread vs average team)
- `model_params_2025` (sigma + home field)
- `target_game` (select matchup without hardcoding IDs)
- `matchup_probability_v2` (final output)
- chart views (two-row format for bar charts)

---

## Why the `target_game` Table Exists (Recruiter-grade pattern)
Hardcoding a `game_id` is brittle. Schedules differ, naming conventions differ, playoffs differ.

Instead, we:
1) define the target matchup by business logic (date + teams)
2) store that result in `workspace.nfl_gold.target_game`
3) use it downstream in modeling and chart views

This pattern prevents “empty CTE” failures and makes the pipeline reusable for any matchup.

---

## Data Quality / Validation Strategy

Examples of checks run during development:
- key uniqueness:
  - `weather_2025`: 1 row per `game_id`
  - `team_game_basic_2025`: 1 row per `(game_id, team)`
- home/away sanity:
  - each game should have exactly one home row and one away row
- plausibility checks:
  - temp and wind within reasonable ranges
- modeling checks:
  - win probabilities sum to 1

These checks belong in `sql/90_data_quality_checks.sql` and should be runnable anytime.

---

## Model Summary (Current Version)
- Strength proxy: point differential (baseline + recent form)
- Shrinkage: stabilize ratings by reducing small-sample volatility
- Probability mapping: use observed margin volatility (`margin_sigma`) to map predicted margin to win probability
- Output: win probability per team + spread rating per team

---

## Extension Plan (Future Bronze/Silver/Gold additions)
To improve predictive accuracy:
- add injury reports + availability
- add snap counts / starters
- add play-by-play EPA and pace
- calibrate model spread ratings vs market spreads
