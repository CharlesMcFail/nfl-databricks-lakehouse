-- ============================================================
-- 20_silver_clean.sql
-- Purpose: Build cleaned, typed, deduplicated Silver tables.
-- ============================================================

USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS nfl_silver;

-- ------------------------------------------------------------
-- SILVER: weather_2025
-- Confirmed columns:
-- game_id, season, week, game_type, game_date, home_team, away_team,
-- temp_f, wind_mph, roof, surface, stadium
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_silver.weather_2025
USING DELTA
AS
SELECT DISTINCT
  CAST(game_id AS STRING)      AS game_id,
  TRY_CAST(season AS INT)      AS season,
  TRY_CAST(week AS INT)        AS week,
  CAST(game_type AS STRING)    AS game_type,
  TO_DATE(game_date)           AS game_date,
  CAST(home_team AS STRING)    AS home_team,
  CAST(away_team AS STRING)    AS away_team,
  TRY_CAST(temp_f AS DOUBLE)   AS temp_f,
  TRY_CAST(wind_mph AS DOUBLE) AS wind_mph,
  CAST(roof AS STRING)         AS roof,
  CAST(surface AS STRING)      AS surface,
  CAST(stadium AS STRING)      AS stadium,
  current_timestamp()          AS _silver_created_ts
FROM workspace.nfl_bronze.weather_2025_bronze
WHERE game_id IS NOT NULL;

-- ------------------------------------------------------------
-- SILVER: market_odds_2025
-- Confirmed columns:
-- game_id, season, week, game_type, game_date, home_team, away_team,
-- spread_line, total_line, home_moneyline, away_moneyline,
-- home_spread_odds, away_spread_odds, over_odds, under_odds
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_silver.market_odds_2025
USING DELTA
AS
SELECT DISTINCT
  CAST(game_id AS STRING)           AS game_id,
  TRY_CAST(season AS INT)           AS season,
  TRY_CAST(week AS INT)             AS week,
  CAST(game_type AS STRING)         AS game_type,
  TO_DATE(game_date)                AS game_date,
  CAST(home_team AS STRING)         AS home_team,
  CAST(away_team AS STRING)         AS away_team,
  TRY_CAST(spread_line AS DOUBLE)   AS spread_line,
  TRY_CAST(total_line AS DOUBLE)    AS total_line,
  TRY_CAST(home_moneyline AS DOUBLE) AS home_moneyline,
  TRY_CAST(away_moneyline AS DOUBLE) AS away_moneyline,
  TRY_CAST(home_spread_odds AS DOUBLE) AS home_spread_odds,
  TRY_CAST(away_spread_odds AS DOUBLE) AS away_spread_odds,
  TRY_CAST(over_odds AS DOUBLE)     AS over_odds,
  TRY_CAST(under_odds AS DOUBLE)    AS under_odds,
  current_timestamp()               AS _silver_created_ts
FROM workspace.nfl_bronze.market_odds_2025_bronze
WHERE game_id IS NOT NULL;

-- ------------------------------------------------------------
-- SILVER: team_game_basic_2025
-- Confirmed columns:
-- game_id, season, week, game_type, game_date, team, opponent, is_home,
-- points_for, points_against, point_diff, rest_days,
-- spread_line_home, moneyline, total_line,
-- temp_f, wind_mph, roof, surface, stadium
-- ------------------------------------------------------------
CREATE OR REPLACE TABLE workspace.nfl_silver.team_game_basic_2025
USING DELTA
AS
SELECT DISTINCT
  CAST(game_id AS STRING)                      AS game_id,
  TRY_CAST(season AS INT)                      AS season,
  TRY_CAST(week AS INT)                        AS week,
  CAST(game_type AS STRING)                    AS game_type,
  TO_DATE(game_date)                           AS game_date,
  CAST(team AS STRING)                         AS team,
  CAST(opponent AS STRING)                     AS opponent,
  TRY_CAST(is_home AS INT)                     AS is_home,
  TRY_CAST(points_for AS INT)                  AS points_for,
  TRY_CAST(points_against AS INT)              AS points_against,
  (TRY_CAST(points_for AS DOUBLE) - TRY_CAST(points_against AS DOUBLE)) AS point_diff,
  TRY_CAST(rest_days AS INT)                   AS rest_days,
  TRY_CAST(spread_line_home AS DOUBLE)         AS spread_line_home,
  TRY_CAST(moneyline AS DOUBLE)                AS moneyline,
  TRY_CAST(total_line AS DOUBLE)               AS total_line,
  TRY_CAST(temp_f AS DOUBLE)                   AS temp_f,
  TRY_CAST(wind_mph AS DOUBLE)                 AS wind_mph,
  CAST(roof AS STRING)                         AS roof,
  CAST(surface AS STRING)                      AS surface,
  CAST(stadium AS STRING)                      AS stadium,
  current_timestamp()                          AS _silver_created_ts
FROM workspace.nfl_bronze.team_game_stats_basic_2025_bronze
WHERE game_id IS NOT NULL
  AND team IS NOT NULL;

-- ------------------------------------------------------------
-- SILVER: games_2025
-- NOTE: Your environment already has workspace.nfl_silver.games_2025.
-- This script DOES NOT recreate it because we haven't confirmed its full schema
-- in this chat (some columns like scores may exist).
--
-- Recruiter-friendly best practice:
-- Export your exact definition using:
-- SHOW CREATE TABLE workspace.nfl_silver.games_2025;
-- and paste it into a separate file if you want.
-- ------------------------------------------------------------

-- Verify Silver confirms expected objects exist
SHOW TABLES IN workspace.nfl_silver;
