-- 自動化的維度資料建模處理腳本
-- 使用方法：修改start_year和end_year變數即可

DO $$
DECLARE
    start_year INTEGER := 1995;
    end_year INTEGER := 2000;
    current_year INTEGER;
    prev_year INTEGER;
BEGIN
    -- 迴圈處理每一年
    FOR current_year IN (start_year + 1)..(end_year) LOOP
        prev_year := current_year - 1;
        
        RAISE NOTICE '正在處理年份: % -> %', prev_year, current_year;
        
        -- 動態執行INSERT語句
        EXECUTE format('
            INSERT INTO players
            WITH yesterday AS (
              SELECT * FROM players
              WHERE current_season = %s
            ),
            today AS (
              SELECT * FROM player_seasons
              WHERE season = %s
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

                CASE 
                    WHEN t.season IS NOT NULL THEN 
                      CASE WHEN t.pts > 20 THEN ''star''
                      WHEN t.pts > 15 THEN ''good''
                      WHEN t.pts > 10 THEN ''average''
                      ELSE ''bad''
                      END::scoring_class
                    ELSE y.scoring_class
                END as scoring_class,

                CASE WHEN t.season IS NOT NULL THEN 0
                    ELSE y.years_since_last_season + 1
                END as years_since_last_season,

                COALESCE(t.season, y.current_season + 1) as current_season
              
            FROM today t FULL OUTER JOIN yesterday y
              ON t.player_name = y.player_name
        ', prev_year, current_year);
        
        RAISE NOTICE '完成年份: % -> %', prev_year, current_year;
    END LOOP;
    
    RAISE NOTICE '所有年份處理完成！從 % 到 %', start_year, end_year;
END $$;

-- 檢查結果
SELECT 
    current_season,
    COUNT(*) as player_count,
    COUNT(DISTINCT player_name) as unique_players
FROM players 
WHERE current_season BETWEEN 1996 AND 2000
GROUP BY current_season
ORDER BY current_season; 