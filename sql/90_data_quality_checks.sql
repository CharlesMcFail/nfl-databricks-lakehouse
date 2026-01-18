-- ============================================================
-- 90_data_quality_checks.sql
-- Purpose: Repeatable validation checks for Bronze/Silver/Gold
-- ============================================================

USE CATALOG workspace;

-- ------------------------------------------------------------
-- SILVER CHECKS
-- ------------------------------------------------------------

-- 1) weather_2025 should have 1 row per game_id
SELECT game_id, COUNT(*) AS cnt
FROM workspace.nfl_silver.weather_2025
GROUP BY game_id
HAVING COUNT(*) > 1;

-- 2) market_odds_2025 should have 1 row per game_id
SELECT game_id, COUNT(*) AS cnt
FROM workspace.nfl_silver.market_odds_2025
GROUP BY game_id
HAVING COUNT(*) > 1;

-- 3) team_game_basic_2025 should have 1 row per (game_id, team)
SELECT game_id, team, COUNT(*) AS cnt
FROM workspace.nfl_silver.team_game_basic_2025
GROUP BY game_id, team
HAVING COUNT(*) > 1;

-- 4) each game should have exactly 1 home row and 1 away row
SELECT
  game_id,
  SUM(CASE WHEN is_home = 1 THEN 1 ELSE 0 END) AS home_rows,
  SUM(CASE WHEN is_home = 0 THEN 1 ELSE 0 END) AS away_rows,
  COUNT(*) AS total_rows
FROM workspace.nfl_silver.team_game_basic_2025
GROUP BY game_id
HAVING home_rows != 1 OR away_rows != 1 OR total_rows != 2;

-- 5) plausibility: temperatures and wind (should return few/none)
SELECT *
FROM workspace.nfl_silver.weather_2025
WHERE (temp_f < -40 OR temp_f > 130 OR wind_mph < 0 OR wind_mph > 80)
LIMIT 50;

-- ------------------------------------------------------------
-- GOLD CHECKS
-- ------------------------------------------------------------

-- 6) game_features_2025 should have 1 row per game_id
SELECT game_id, COUNT(*) AS cnt
FROM workspace.nfl_gold.game_features_2025
GROUP BY game_id
HAVING COUNT(*) > 1;

-- 7) model_params_2025 should be 1 row and sigma should not be null
SELECT * FROM workspace.nfl_gold.model_params_2025;

-- 8) target_game should be exactly 1 row (for the selected matchup)
SELECT COUNT(*) AS target_game_rows
FROM workspace.nfl_gold.target_game;

SELECT * FROM workspace.nfl_gold.target_game;

-- 9) matchup_probability_v2 should be exactly 1 row
SELECT COUNT(*) AS matchup_rows
FROM workspace.nfl_gold.matchup_probability_v2;

-- 10) probabilities should sum to 1 (within floating error)
SELECT
  (home_win_prob + away_win_prob) AS prob_sum
FROM workspace.nfl_gold.matchup_probability_v2;

-- 11) chart view should have 2 rows and sum to 1
SELECT COUNT(*) AS chart_rows
FROM workspace.nfl_gold.matchup_probability_v2_chart;

SELECT SUM(win_prob) AS chart_prob_sum
FROM workspace.nfl_gold.matchup_probability_v2_chart;

-- 12) team spread rating should have 32 teams
SELECT COUNT(DISTINCT team) AS team_count
FROM workspace.nfl_gold.team_spread_rating_v2;
