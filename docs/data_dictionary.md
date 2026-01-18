# Data Dictionary

This project follows a medallion architecture inside Unity Catalog:

- `workspace.nfl_bronze`: raw ingested CSV tables (minimal changes)
- `workspace.nfl_silver`: cleaned, typed, deduplicated tables (trust layer)
- `workspace.nfl_gold`: analytics features + model outputs (business layer)

This dictionary documents key tables and the columns most relevant to the model.

---

## Bronze Layer Tables (Raw)

### `workspace.nfl_bronze.games_2025_bronze`
**Grain:** 1 row per game  
**Purpose:** game key backbone (`game_id`), schedule, teams, dates.

Common fields:
- `game_id` (string): unique game identifier
- `season` (int)
- `week` (int)
- `game_type` (string): REG / POST / etc.
- `game_date` (date)
- `home_team` (string)
- `away_team` (string)

---

### `workspace.nfl_bronze.weather_2025_bronze`
**Grain:** 1 row per game  
**Purpose:** environment metadata (stadium, roof, surface, temp/wind).

Fields confirmed in this project:
- `game_id`
- `season`
- `week`
- `game_type`
- `game_date`
- `home_team`
- `away_team`
- `temp_f` (nullable)
- `wind_mph` (nullable)
- `roof`
- `surface`
- `stadium`

---

### `workspace.nfl_bronze.market_odds_2025_bronze`
**Grain:** 1 row per game  
**Purpose:** market pricing (spread/total/moneyline and odds).

Fields confirmed:
- `game_id`
- `season`
- `week`
- `game_type`
- `game_date`
- `home_team`
- `away_team`
- `spread_line` (home spread)
- `total_line`
- `home_moneyline`
- `away_moneyline`
- `home_spread_odds`
- `away_spread_odds`
- `over_odds`
- `under_odds`

---

### `workspace.nfl_bronze.team_game_stats_basic_2025_bronze`
**Grain:** 2 rows per game (one per team)  
**Purpose:** team-level performance inputs.

Fields confirmed:
- `game_id`
- `season`
- `week`
- `game_type`
- `game_date`
- `team`
- `opponent`
- `is_home` (0/1)
- `points_for`
- `points_against`
- `point_diff` (may be derived)
- `rest_days`
- `spread_line_home`
- `moneyline`
- `total_line`
- `temp_f`
- `wind_mph`
- `roof`
- `surface`
- `stadium`

---

## Silver Layer Tables (Clean / Typed)

### `workspace.nfl_silver.games_2025`
**Grain:** 1 row per game  
**Purpose:** trusted schedule backbone for joins; typed dates/ids.

Key fields:
- `game_id`, `game_date`, `home_team`, `away_team`, `season`, `week`, `game_type`
- may also include score fields (if present): `home_score`, `away_score`

---

### `workspace.nfl_silver.weather_2025`
**Grain:** 1 row per game  
**Purpose:** cleaned weather metadata.

Same fields as Bronze weather, typed and deduplicated.

---

### `workspace.nfl_silver.market_odds_2025`
**Grain:** 1 row per game  
**Purpose:** cleaned odds, typed numerics.

Same fields as Bronze odds, typed and deduplicated.

---

### `workspace.nfl_silver.team_game_basic_2025`
**Grain:** 2 rows per game (one per team)  
**Purpose:** clean team-game dataset for baseline + recent form calculations.

Key fields:
- `game_id`, `game_date`, `team`, `opponent`, `is_home`
- `points_for`, `points_against`, `point_diff`, `rest_days`

---

## Gold Layer (Analytics / Model)

### `workspace.nfl_gold.team_power_v2_2025`
**Grain:** 1 row per team  
**Purpose:** baseline + recent form → team power score.

Key fields:
- `team`
- `games_played_reg`
- `baseline_raw`, `recent_form_raw`
- `baseline_shrunk`, `recent_form_shrunk`
- `power_score_v2`

---

### `workspace.nfl_gold.team_spread_rating_v2` (view)
**Grain:** 1 row per team  
**Purpose:** translate team power into “spread vs average team”.

Key fields:
- `team`
- `games_played_reg`
- `spread_vs_avg_neutral`
- `spread_vs_avg_as_home`
- `spread_vs_avg_as_away`

---

### `workspace.nfl_gold.target_game`
**Grain:** 1 row (the selected matchup)  
**Purpose:** prevents hardcoding game_id; used downstream.

Key fields:
- `game_id`, `game_date`, `home_team`, `away_team`

---

### `workspace.nfl_gold.model_params_2025`
**Grain:** 1 row  
**Purpose:** model calibration parameters.

Key fields:
- `margin_sigma` (std dev of score margin from completed games)
- `home_field_points`

---

### `workspace.nfl_gold.matchup_probability_v2`
**Grain:** 1 row (per selected matchup)  
**Purpose:** final probability output.

Key fields:
- `game_id`, `home_team`, `away_team`
- `margin_pred_points`
- `home_win_prob`, `away_win_prob`

---

### `workspace.nfl_gold.matchup_probability_v2_chart` (view)
**Grain:** 2 rows (one per team)  
**Purpose:** chart-friendly format.

Fields:
- `team`
- `win_prob`

---

## Notes
This dictionary reflects the columns confirmed in the working Databricks environment and is designed to stay aligned with your pipeline as you evolve it.
