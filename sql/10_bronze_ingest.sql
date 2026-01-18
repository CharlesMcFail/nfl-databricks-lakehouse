-- ============================================================
-- 10_bronze_ingest.sql
-- Purpose: Load raw CSVs into Bronze tables (raw truth).
-- Catalog: workspace
-- Schemas: nfl_bronze, nfl_silver, nfl_gold
-- ============================================================

USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS nfl_bronze;

-- ------------------------------------------------------------
-- IMPORTANT NOTE
-- There are multiple ways to ingest CSVs into Databricks.
-- This file documents a robust approach using a Unity Catalog Volume.
-- If your Bronze tables already exist (as in your current environment),
-- you can skip the COPY INTO steps and only use the verification queries.
-- ------------------------------------------------------------

-- ============================================================
-- OPTION 1 (Recommended): Use a Unity Catalog Volume + COPY INTO
-- ============================================================
-- Step 1: Create a Volume (one-time). If you already have a volume
-- (you do: workspace.nfl_bronze.raw_files), you can skip this.
-- Example:
-- CREATE VOLUME IF NOT EXISTS workspace.nfl_bronze.raw_files;

-- Step 2: Upload CSVs via Databricks UI to a folder in the Volume, e.g.:
-- /Volumes/workspace/nfl_bronze/raw_files/
-- Files expected:
-- - games_2025.csv
-- - weather_2025.csv
-- - market_odds_2025.csv
-- - team_game_stats_basic_2025.csv

-- Step 3: Create Bronze tables that match your CSV columns.
-- You can create them as "schema-on-read" or explicitly define columns.
-- The simplest pattern is:
--  - Create an empty Delta table with the columns you expect
--  - COPY INTO to load rows

-- NOTE: Column definitions vary by source; you already have working tables.
-- For an exact schema, use:
-- DESCRIBE TABLE workspace.nfl_bronze.<table_name>;

-- Step 4: COPY INTO examples (uncomment and edit file paths if needed)
-- COPY INTO workspace.nfl_bronze.games_2025_bronze
-- FROM '/Volumes/workspace/nfl_bronze/raw_files/games_2025.csv'
-- FILEFORMAT = CSV
-- FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mode' = 'PERMISSIVE');

-- COPY INTO workspace.nfl_bronze.weather_2025_bronze
-- FROM '/Volumes/workspace/nfl_bronze/raw_files/weather_2025.csv'
-- FILEFORMAT = CSV
-- FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mode' = 'PERMISSIVE');

-- COPY INTO workspace.nfl_bronze.market_odds_2025_bronze
-- FROM '/Volumes/workspace/nfl_bronze/raw_files/market_odds_2025.csv'
-- FILEFORMAT = CSV
-- FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mode' = 'PERMISSIVE');

-- COPY INTO workspace.nfl_bronze.team_game_stats_basic_2025_bronze
-- FROM '/Volumes/workspace/nfl_bronze/raw_files/team_game_stats_basic_2025.csv'
-- FILEFORMAT = CSV
-- FORMAT_OPTIONS ('header' = 'true', 'inferSchema' = 'true', 'mode' = 'PERMISSIVE');

-- ============================================================
-- OPTION 2: Verification (works even if you already ingested data)
-- ============================================================

SHOW TABLES IN workspace.nfl_bronze;

-- Inspect schemas
DESCRIBE TABLE workspace.nfl_bronze.games_2025_bronze;
DESCRIBE TABLE workspace.nfl_bronze.weather_2025_bronze;
DESCRIBE TABLE workspace.nfl_bronze.market_odds_2025_bronze;
DESCRIBE TABLE workspace.nfl_bronze.team_game_stats_basic_2025_bronze;

-- Quick sample
SELECT * FROM workspace.nfl_bronze.games_2025_bronze LIMIT 10;
SELECT * FROM workspace.nfl_bronze.weather_2025_bronze LIMIT 10;
SELECT * FROM workspace.nfl_bronze.market_odds_2025_bronze LIMIT 10;
SELECT * FROM workspace.nfl_bronze.team_game_stats_basic_2025_bronze LIMIT 10;
