SELECT * FROM player_seasons;

-- 第一步：只執行 DDL 部分
DROP TABLE IF EXISTS players;
DROP TYPE IF EXISTS season_stats;

CREATE TYPE season_stats AS (
  season INTEGER,
  gp INTEGER,
  pts REAL,
  reb REAL,
  ast REAL
);

CREATE TYPE scoring_class AS
  ENUM ('bad', 'average', 'good', 'star');

-- Lab1 Players Table
CREATE TABLE players (
    player_name TEXT,
    height TEXT,
    college TEXT,
    country TEXT,
    draft_year TEXT,
    draft_round TEXT,
    draft_number TEXT,
    seasons season_stats[],
    scoring_class scoring_class,
    years_since_last_active INTEGER,
    is_active BOOLEAN,
    current_season INTEGER,
    PRIMARY KEY (player_name, current_season)
);

-- Lab2 SCD Table
create table players_scd_table
(
	player_name text,
	scoring_class scoring_class,
	is_active boolean,
	start_season integer,
	end_date integer,
	current_season INTEGER,
  PRIMARY KEY (player_name, current_season)
);

-- 第二步：確認表格建立成功後，再執行查詢
SELECT * FROM player_seasons;
SELECT MIN(season) FROM player_seasons;

SELECT player_name, scoring_class, is_active
FROM players
WHERE current_season = 2022;

SELECT
  player_name,
  scoring_class,
  current_season,
  is_active,
  LAG(is_active) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_scoring_class,
  LAG(scoring_class) OVER (PARTITION BY player_name ORDER BY current_season) AS previous_is_active
FROM players