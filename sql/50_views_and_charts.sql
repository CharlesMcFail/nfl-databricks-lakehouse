-- ============================================================
-- 50_views_and_charts.sql
-- Purpose: Views used directly for Databricks visualizations
-- ============================================================

USE CATALOG workspace;

CREATE SCHEMA IF NOT EXISTS nfl_gold;

-- ------------------------------------------------------------
-- View: matchup_probability_v2_chart
-- Two-row output for bar charts
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW workspace.nfl_gold.matchup_probability_v2_chart AS
WITH x AS (SELECT * FROM workspace.nfl_gold.matchup_probability_v2)
SELECT home_team AS team, home_win_prob AS win_prob FROM x
UNION ALL
SELECT away_team AS team, away_win_prob AS win_prob FROM x;

-- ------------------------------------------------------------
-- View: team_power_ranking_v2
-- Helpful for ranking charts and debugging
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW workspace.nfl_gold.team_power_ranking_v2 AS
SELECT
  team,
  games_played_reg,
  baseline_raw,
  recent_form_raw,
  baseline_shrunk,
  recent_form_shrunk,
  power_score_v2
FROM workspace.nfl_gold.team_power_v2_2025;
