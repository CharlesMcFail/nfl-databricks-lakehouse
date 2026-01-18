-- ============================================================
-- 30_gold_features.sql
-- Purpose: Build reusable Gold feature tables/views
-- ============================================================

USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS nfl_gold;

-- ------------------------------------------------------------
-- GOLD: weather_features_2025
-- Handles missing weather (common for future games)
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.weather_features_2025
USING DELTA
AS
SELECT
  game_id,
  game_date,
  home_team,
  away_team,
  roof,
  surface,
  stadium,
  CASE WHEN lower(roof) IN ('dome','closed') THEN 1 ELSE 0 END AS is_indoor,
  CASE WHEN lower(roof) = 'outdoors' THEN 1 ELSE 0 END AS is_outdoors,
  CASE
    WHEN temp_f IS NOT NULL THEN CAST(temp_f AS DOUBLE)
    WHEN lower(roof) IN ('dome','closed') THEN 70.0
    ELSE 45.0
  END AS temp_f_filled,
  CASE
    WHEN wind_mph IS NOT NULL THEN CAST(wind_mph AS DOUBLE)
    WHEN lower(roof) IN ('dome','closed') THEN 0.0
    ELSE 10.0
  END AS wind_mph_filled,
  CASE WHEN temp_f IS NOT NULL AND wind_mph IS NOT NULL THEN 1 ELSE 0 END AS weather_known,
  current_timestamp() AS _gold_created_ts
FROM workspace.nfl_silver.weather_2025
WHERE game_id IS NOT NULL;

-- ------------------------------------------------------------
-- GOLD: market_odds_features_2025
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.market_odds_features_2025
USING DELTA
AS
SELECT
  game_id,
  game_date,
  home_team,
  away_team,
  CAST(spread_line AS DOUBLE) AS spread_line,
  CAST(total_line AS DOUBLE) AS total_line,
  CAST(home_moneyline AS DOUBLE) AS home_moneyline,
  CAST(away_moneyline AS DOUBLE) AS away_moneyline,
  CAST(home_spread_odds AS DOUBLE) AS home_spread_odds,
  CAST(away_spread_odds AS DOUBLE) AS away_spread_odds,
  CAST(over_odds AS DOUBLE) AS over_odds,
  CAST(under_odds AS DOUBLE) AS under_odds,
  CASE WHEN CAST(spread_line AS DOUBLE) < 0 THEN 1 ELSE 0 END AS home_favored_flag,
  ABS(CAST(spread_line AS DOUBLE)) AS spread_abs,
  current_timestamp() AS _gold_created_ts
FROM workspace.nfl_silver.market_odds_2025
WHERE game_id IS NOT NULL;

-- ------------------------------------------------------------
-- GOLD: game_features_2025
-- One row per game (joins schedule + team stats + weather + odds)
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.game_features_2025
USING DELTA
AS
WITH home AS (
  SELECT
    game_id,
    team AS home_team,
    point_diff AS home_point_diff,
    rest_days AS home_rest_days
  FROM workspace.nfl_silver.team_game_basic_2025
  WHERE is_home = 1
),
away AS (
  SELECT
    game_id,
    team AS away_team,
    point_diff AS away_point_diff,
    rest_days AS away_rest_days
  FROM workspace.nfl_silver.team_game_basic_2025
  WHERE is_home = 0
)
SELECT
  g.game_id,
  g.game_date,
  g.home_team,
  g.away_team,

  h.home_point_diff,
  a.away_point_diff,
  h.home_rest_days,
  a.away_rest_days,
  (h.home_rest_days - a.away_rest_days) AS rest_days_diff,

  w.is_indoor,
  w.is_outdoors,
  w.temp_f_filled,
  w.wind_mph_filled,
  w.weather_known,

  o.spread_line,
  o.total_line,
  o.home_moneyline,
  o.away_moneyline,
  o.home_spread_odds,
  o.away_spread_odds,
  o.over_odds,
  o.under_odds,
  o.home_favored_flag,
  o.spread_abs,

  current_timestamp() AS _gold_created_ts
FROM workspace.nfl_silver.games_2025 g
LEFT JOIN home h ON g.game_id = h.game_id
LEFT JOIN away a ON g.game_id = a.game_id
LEFT JOIN workspace.nfl_gold.weather_features_2025 w ON g.game_id = w.game_id
LEFT JOIN workspace.nfl_gold.market_odds_features_2025 o ON g.game_id = o.game_id
WHERE g.game_id IS NOT NULL;

-- ------------------------------------------------------------
-- GOLD: team_baseline_2025 (REG only)
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.team_baseline_2025
USING DELTA
AS
SELECT
  team,
  COUNT(*) AS games_played_reg,
  AVG(point_diff) AS avg_point_diff_reg
FROM workspace.nfl_silver.team_game_basic_2025
WHERE points_for IS NOT NULL
  AND game_type = 'REG'
GROUP BY team;

-- ------------------------------------------------------------
-- GOLD: team_recent_form_2025 (last 5 REG games)
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.team_recent_form_2025
USING DELTA
AS
WITH ranked AS (
  SELECT
    team,
    game_date,
    point_diff,
    ROW_NUMBER() OVER (PARTITION BY team ORDER BY game_date DESC) AS rn
  FROM workspace.nfl_silver.team_game_basic_2025
  WHERE points_for IS NOT NULL
    AND game_type = 'REG'
)
SELECT
  team,
  AVG(point_diff) AS avg_point_diff_last_5_reg
FROM ranked
WHERE rn <= 5
GROUP BY team;

-- ------------------------------------------------------------
-- GOLD: team_power_v2_2025 (shrinkage + recent weighting)
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.team_power_v2_2025
USING DELTA
AS
SELECT
  b.team,
  b.games_played_reg,
  b.avg_point_diff_reg AS baseline_raw,
  COALESCE(f.avg_point_diff_last_5_reg, 0) AS recent_form_raw,

  (b.avg_point_diff_reg * (b.games_played_reg / (b.games_played_reg + 5.0))) AS baseline_shrunk,
  (COALESCE(f.avg_point_diff_last_5_reg, 0) * (5.0 / (5.0 + 5.0))) AS recent_form_shrunk,

  (
    (b.avg_point_diff_reg * (b.games_played_reg / (b.games_played_reg + 5.0)))
    + 0.7 * (COALESCE(f.avg_point_diff_last_5_reg, 0) * (5.0 / (5.0 + 5.0)))
  ) AS power_score_v2,

  current_timestamp() AS _gold_created_ts
FROM workspace.nfl_gold.team_baseline_2025 b
LEFT JOIN workspace.nfl_gold.team_recent_form_2025 f
  ON b.team = f.team;

-- ------------------------------------------------------------
-- GOLD VIEW: team_spread_rating_v2 (centered around league average)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW workspace.nfl_gold.team_spread_rating_v2 AS
WITH league_avg AS (
  SELECT AVG(CAST(power_score_v2 AS DOUBLE)) AS avg_power
  FROM workspace.nfl_gold.team_power_v2_2025
),
params AS (
  -- If model_params_2025 doesn't exist yet, home field defaults can be used
  SELECT COALESCE(MAX(CAST(home_field_points AS DOUBLE)), 1.5) AS hfa
  FROM workspace.nfl_gold.model_params_2025
)
SELECT
  p.team,
  p.games_played_reg,
  (CAST(p.power_score_v2 AS DOUBLE) - league_avg.avg_power) AS spread_vs_avg_neutral,
  (CAST(p.power_score_v2 AS DOUBLE) - league_avg.avg_power + params.hfa) AS spread_vs_avg_as_home,
  (CAST(p.power_score_v2 AS DOUBLE) - league_avg.avg_power - params.hfa) AS spread_vs_avg_as_away
FROM workspace.nfl_gold.team_power_v2_2025 p
CROSS JOIN league_avg
CROSS JOIN params;
