-- ============================================================
-- 99_drop_objects.sql
-- Purpose: Drop objects to rebuild pipeline cleanly
-- ============================================================

USE CATALOG workspace;

-- GOLD objects (drop first because they depend on Silver)
DROP VIEW IF EXISTS workspace.nfl_gold.matchup_probability_v2_chart;
DROP VIEW IF EXISTS workspace.nfl_gold.team_power_ranking_v2;
DROP VIEW IF EXISTS workspace.nfl_gold.team_spread_rating_v2;

DROP TABLE IF EXISTS workspace.nfl_gold.matchup_probability_v2;
DROP TABLE IF EXISTS workspace.nfl_gold.target_game;
DROP TABLE IF EXISTS workspace.nfl_gold.model_params_2025;

DROP TABLE IF EXISTS workspace.nfl_gold.team_power_v2_2025;
DROP TABLE IF EXISTS workspace.nfl_gold.team_recent_form_2025;
DROP TABLE IF EXISTS workspace.nfl_gold.team_baseline_2025;

DROP TABLE IF EXISTS workspace.nfl_gold.game_features_2025;
DROP TABLE IF EXISTS workspace.nfl_gold.market_odds_features_2025;
DROP TABLE IF EXISTS workspace.nfl_gold.weather_features_2025;

-- SILVER objects
DROP TABLE IF EXISTS workspace.nfl_silver.team_game_basic_2025;
DROP TABLE IF EXISTS workspace.nfl_silver.market_odds_2025;
DROP TABLE IF EXISTS workspace.nfl_silver.weather_2025;

-- NOTE: We do NOT drop workspace.nfl_silver.games_2025 here because it may
-- include extra columns you want to preserve and we didn't recreate it in our scripts.
-- Drop it only if you explicitly want to rebuild it:
-- DROP TABLE IF EXISTS workspace.nfl_silver.games_2025;

-- BRONZE objects (optional; comment out if you want to keep raw data)
-- DROP TABLE IF EXISTS workspace.nfl_bronze.team_game_stats_basic_2025_bronze;
-- DROP TABLE IF EXISTS workspace.nfl_bronze.market_odds_2025_bronze;
-- DROP TABLE IF EXISTS workspace.nfl_bronze.weather_2025_bronze;
-- DROP TABLE IF EXISTS workspace.nfl_bronze.games_2025_bronze;
