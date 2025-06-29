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
