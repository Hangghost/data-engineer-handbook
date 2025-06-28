SELECT * FROM player_seasons;

-- 第一步：只執行 DDL 部分
DROP TABLE IF EXISTS players;

CREATE TYPE season_stats AS (
  season INTEGER,
  gp INTEGER,
  pts REAL,
  reb REAL,
  ast REAL
);

CREATE TABLE players (
  player_name TEXT,
  height TEXT,
  college TEXT,
  country TEXT,
  draft_year TEXT,
  draft_round TEXT,
  draft_number TEXT,
  season_stats season_stats[],
  current_season INTEGER,
  PRIMARY KEY (player_name, current_season)
);

-- 第二步：確認表格建立成功後，再執行查詢
SELECT * FROM player_seasons;
SELECT MIN(season) FROM player_seasons;

-- 第三步：執行複雜的分析查詢
WITH yesterday AS (
  SELECT * FROM players
  WHERE current_season = 1995
),
  today AS (
  SELECT * FROM player_seasons
  WHERE season = 1996
  )

SELECT
    COALESCE(t.player_name, y.player_name) AS player_name,
    COALESCE(t.height, y.height) AS height,
    COALESCE(t.college, y.college) AS college,
    COALESCE(t.country, y.country) AS country,
    COALESCE(t.draft_number, y.draft_number) AS draft_number,
    COALESCE(t.draft_year, y.draft_year) AS draft_year,
    COALESCE(t.draft_round, y.draft_round) AS draft_round,

    CASE WHEN y.season_stats IS NULL
      THEN ARRAY[ROW(
        t.season,
        t.gp,
        t.pts,
        t.reb,
        t.ast
      )::season_stats]
    WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY[ROW(
        t.season,
        t.gp,
        t.pts,
        t.reb,
        t.ast
      )::season_stats]
    ELSE y.season_stats
    END as season_stats,
    COALESCE(t.season, y.current_season + 1) as current_season
  
FROM today t FULL OUTER JOIN yesterday y
  ON t.player_name = y.player_name