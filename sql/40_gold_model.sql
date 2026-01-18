-- ============================================================
-- 40_gold_model.sql
-- Purpose: Model parameters + target game + matchup probability
-- ============================================================

USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS nfl_gold;

-- ------------------------------------------------------------
-- GOLD: model_params_2025
-- margin_sigma = observed std dev of home margin for completed games
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.model_params_2025
USING DELTA
AS
SELECT
  STDDEV_SAMP(CAST(home_score AS DOUBLE) - CAST(away_score AS DOUBLE)) AS margin_sigma,
  1.5 AS home_field_points,
  current_timestamp() AS _gold_created_ts
FROM workspace.nfl_silver.games_2025
WHERE home_score IS NOT NULL AND away_score IS NOT NULL;

-- ------------------------------------------------------------
-- GOLD: target_game
-- IMPORTANT: update the WHERE filter if you want a different matchup
-- This prevents hardcoding game_id in downstream logic.
-- Example used here is Texans @ Patriots on 2026-01-18.
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_gold.target_game
USING DELTA
AS
SELECT
  game_id,
  game_date,
  home_team,
  away_team
FROM workspace.nfl_silver.games_2025
WHERE game_date = DATE '2026-01-18'
  AND home_team = 'NE'
  AND away_team = 'HOU';

-- ------------------------------------------------------------
-- GOLD: matchup_probability_v2
-- Uses Normal-CDF via erf() (or you can swap to logistic if needed)
-- DROP first to avoid table lock/corruption edge cases.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS workspace.nfl_gold.matchup_probability_v2;

CREATE OR REPLACE TABLE workspace.nfl_gold.matchup_probability_v2
USING DELTA
AS
WITH params AS (
  SELECT
    COALESCE(NULLIF(CAST(margin_sigma AS DOUBLE), 0.0), 13.5) AS margin_sigma,
    CAST(home_field_points AS DOUBLE) AS home_field_points
  FROM workspace.nfl_gold.model_params_2025
),
tg AS (
  SELECT game_id, game_date, home_team, away_team
  FROM workspace.nfl_gold.target_game
),
p AS (
  SELECT team, CAST(power_score_v2 AS DOUBLE) AS power_score_v2
  FROM workspace.nfl_gold.team_power_v2_2025
),
base AS (
  SELECT
    tg.game_id,
    tg.game_date,
    tg.home_team,
    tg.away_team,
    (hp.power_score_v2 + params.home_field_points - ap.power_score_v2) AS margin_pred_points,
    params.margin_sigma AS margin_sigma
  FROM tg
  JOIN p hp ON tg.home_team = hp.team
  JOIN p ap ON tg.away_team = ap.team
  CROSS JOIN params
)
SELECT
  game_id,
  game_date,
  home_team,
  away_team,
  margin_pred_points,
  0.5 * (1.0 + erf( (margin_pred_points / margin_sigma) / sqrt(2.0) )) AS home_win_prob,
  1.0 - (0.5 * (1.0 + erf( (margin_pred_points / margin_sigma) / sqrt(2.0) ))) AS away_win_prob,
  current_timestamp() AS _gold_created_ts
FROM base;
