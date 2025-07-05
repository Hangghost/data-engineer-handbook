-- 第三步：執行複雜的分析查詢

INSERT INTO players
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

    CASE WHEN y.seasons IS NULL
      THEN ARRAY[ROW(
        t.season,
        t.gp,
        t.pts,
        t.reb,
        t.ast
      )::season_stats]
    WHEN t.season IS NOT NULL THEN y.seasons || ARRAY[ROW(
        t.season,
        t.gp,
        t.pts,
        t.reb,
        t.ast
      )::season_stats]
    ELSE y.seasons
    END as seasons,

    CASE 
        WHEN t.season IS NOT NULL THEN 
          CASE WHEN t.pts > 20 THEN 'star'
          WHEN t.pts > 15 THEN 'good'
          WHEN t.pts > 10 THEN 'average'
          ELSE 'bad'
          END::scoring_class
        ELSE y.scoring_class
    END as scoring_class,

    CASE WHEN t.season IS NOT NULL THEN 0
        ELSE y.years_since_last_active + 1
    END as years_since_last_active,

    CASE WHEN t.season IS NOT NULL THEN true
        ELSE false
    END as is_active,

    COALESCE(t.season, y.current_season + 1) as current_season
  
FROM today t FULL OUTER JOIN yesterday y
  ON t.player_name = y.player_name

-- 第四步：執行 UNNEST 查詢

WITH unnested AS (
  SELECT player_name,
        UNNEST(seasons)::season_stats AS season_stats
  FROM players
  WHERE current_season = 2001
    AND player_name = 'Michael Jordan'
)

SELECT player_name,
  (season_stats::season_stats).*
FROM unnested;

-- 第五步：執行一般查詢

SELECT * FROM players
WHERE current_season = 2001
AND player_name = 'Michael Jordan';

-- 第六步：找出每個人的進步幅度

SELECT 
  player_name,
  (seasons[1]::season_stats).pts AS first_season,
  (seasons[CARDINALITY(seasons)]::season_stats).pts AS last_season
FROM players
WHERE current_season = 2001
AND player_name = 'Michael Jordan';

-- 第七步：找出每個人的進步幅度 ratio

SELECT 
  player_name,
  (seasons[CARDINALITY(seasons)]::season_stats).pts/
  CASE WHEN (seasons[1]::season_stats).pts = 0
    THEN 1
    ELSE (seasons[1]::season_stats).pts
  END
FROM players
WHERE current_season = 2001
ORDER BY 2 DESC;