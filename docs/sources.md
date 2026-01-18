# Data Sources (Bronze Layer)

This project is a Databricks SQL + Lakehouse demo built using publicly available NFL datasets.
To keep this repository lightweight and avoid redistribution issues, the full raw datasets are not stored here.
Instead, this doc provides the source links and the exact tables/files represented in the Bronze layer.

---

## Bronze Inputs in This Project

### 1) Games / schedule / IDs (primary key backbone)
**What it provides**
- `game_id`, `season`, `week`, `game_type`, `game_date`
- `home_team`, `away_team`
- Identifiers and metadata used to join across weather, odds, and team-game stats

**Source**
- nflverse / nflreadr schedules dataset:
  - https://nflreadr.nflverse.com/reference/load_schedules.html
  - https://nflverse.nflverse.com/

**How it maps to our Bronze tables**
- `workspace.nfl_bronze.games_2025_bronze`

---

### 2) Weather metadata (game environment)
**What it provides**
- Stadium + environment fields used for feature engineering
- In this project’s dataset, the weather table includes:
  - `temp_f`, `wind_mph`, `roof`, `surface`, `stadium`
- NOTE: Future games may have missing weather values; Gold layer handles nulls safely.

**Source**
- Derived from/packaged alongside the schedule dataset in nflverse-style outputs (same `game_id` join key)

**How it maps to our Bronze tables**
- `workspace.nfl_bronze.weather_2025_bronze`

---

### 3) Market odds (spread / total / moneyline)
**What it provides**
- `spread_line`, `total_line`, `home_moneyline`, `away_moneyline`
- odds pricing: `home_spread_odds`, `away_spread_odds`, `over_odds`, `under_odds`
- Used as an “external consensus” feature set (market signal)

**Source**
- The project uses an odds dataset aligned to the schedule by `game_id` and date.
- If you want a clean, independently verifiable odds provider going forward, these are common:
  - The Odds API: https://the-odds-api.com/sports-odds-data/nfl-odds.html
  - ESPN odds: https://www.espn.com/nfl/odds
  - FantasyData odds: https://fantasydata.com/nfl/odds

**How it maps to our Bronze tables**
- `workspace.nfl_bronze.market_odds_2025_bronze`

---

### 4) Team game stats (basic)
**What it provides**
- Team-level game rows (2 rows per game: one per team)
- Used to compute baseline strength + recent form
- Key columns in this project:
  - `team`, `opponent`, `is_home`, `points_for`, `points_against`, `rest_days`, `point_diff`

**Source**
- Structured team-game output derived from the game schedule/results dataset using `game_id`

**How it maps to our Bronze tables**
- `workspace.nfl_bronze.team_game_stats_basic_2025_bronze`

---

## Important Notes on Usage Rights
- Underlying NFL data belongs to its respective rights holders.
- This repository focuses on:
  1) engineering a reproducible lakehouse pipeline, and
  2) demonstrating analytics modeling and communication.
- Full raw datasets are not redistributed here; instead, this doc provides source links and the pipeline logic.

---

## Provenance Summary (One-Liner)
Bronze data comes from publicly available nflverse-style schedules/results datasets (joined by `game_id`), plus an aligned odds dataset; Silver and Gold are transformations and derived features built inside Databricks.
