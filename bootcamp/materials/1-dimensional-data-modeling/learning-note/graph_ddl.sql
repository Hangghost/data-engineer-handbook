
DROP TYPE vertex_type CASCADE;
DROP TABLE vertices CASCADE;
DROP TYPE edge_type CASCADE;
DROP TABLE edges CASCADE;


-- 1. Create vertex type and table

CREATE TYPE vertex_type AS ENUM ('player', 'team', 'game');

CREATE TABLE vertices (
    identifier TEXT,
    type vertex_type,
    properties JSON,
    PRIMARY KEY (identifier, type)
);

-- 2. Create edge type and table

CREATE TYPE edge_type AS 
ENUM (
    'plays_against',
    'shares_team',
    'plays_in',
    'plays_on'
);

CREATE TABLE edges (
    -- edge_it TEXT,
    subject_identifier TEXT,
    subject_type vertex_type,
    object_identifier TEXT,
    object_type vertex_type,
    edge_type edge_type,
    properties JSON,
    PRIMARY KEY (subject_identifier, 
                 subject_type, 
                 object_identifier, 
                 object_type,
                 edge_type)
);

-- 3. Insert data into vertices table

INSERT INTO vertices

SELECT
    game_id AS identifier,
    'game'::vertex_type AS type,
    json_build_object(
        'pts_home', pts_home,
        'pts_away', pts_away,
        'winning_team', CASE WHEN home_team_wins = 1 THEN home_team_id ELSE visitor_team_id END
    ) AS properties
FROM games;


-- 4. Insert data into edges table

INSERT INTO vertices
WITH players_agg AS (
    SELECT 
        player_id AS subject_identifier,
        MAX(player_name) as player_name,
        COUNT(1) as number_of_games,
        SUM(pts) as total_points,
        ARRAY_AGG(DISTINCT team_id) as teams
    FROM game_details
    GROUP BY player_id
)

SELECT subject_identifier, 'player'::vertex_type,
    json_build_object(
        'player_name', player_name,
        'number_of_games', number_of_games,
        'total_points', total_points,
        'teams', teams
    )
FROM players_agg;

-- 5. Insert data into vertices table

INSERT INTO vertices

WITH teams_deduped AS (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY team_id) as row_num
    FROM teams
)

SELECT 
    team_id AS identifier,
    'team'::vertex_type AS type,
    json_build_object(
        'abbreviation', abbreviation,
        'nickname', nickname,
        'city', city,
        'arena', arena,
        'year_founded', yearfounded
    ) AS properties
FROM teams_deduped
WHERE row_num = 1;

-- 查詢
SELECT type, COUNT(1)
FROM vertices
GROUP BY 1;


-- 6. Insert data into edges table

INSERT INTO edges
WITH deduped AS (
    SELECT *, row_number() over (PARTITION BY player_id, game_id) AS row_num
    FROM game_details
)

SELECT
    player_id AS subject_identifier,
    'player'::vertex_type as subject_type,
    game_id AS object_identifier,
    'game'::vertex_type AS object_type,
    'plays_in'::edge_type AS edge_type,
    json_build_object(
        'start_position', start_position,
        'pts', pts,
        'team_id', team_id,
        'team_abbreviation', team_abbreviation
    ) as properties
FROM deduped
WHERE row_num = 1;

-- 查詢

SELECT *
FROM vertices v JOIN edges e 
    ON  e.subject_identifier = v.identifier
    AND e.subject_type = v.type

-- 查詢 (正確：每個球員的得分)

SELECT 
    v.properties->>'player_name',
    MAX(e.properties->>'pts')
    FROM vertices v
    JOIN edges e 
    ON e.subject_identifier = v.identifier
    AND e.subject_type = v.type
GROUP BY 1
ORDER BY 2 DESC;

-- 7. Insert data into edges table (細節：每個球員的得分)

INSERT INTO edges
WITH deduped AS (
    SELECT *, row_number() over (PARTITION BY player_id, game_id) AS row_num
    FROM game_details
),
filtered AS (
    SELECT *
    FROM deduped
    WHERE row_num = 1
),
aggregated AS (
    SELECT
        f1.player_id as subject_player_id,
        f2.player_id as object_player_id,
        CASE WHEN f1.team_abbreviation = f2.team_abbreviation 
            THEN 'shares_team'::edge_type
            ELSE 'plays_against'::edge_type
        END as edge_type,

        MAX(f1.player_name) as subject_player_name,
        MAX(f2.player_name) as object_player_name,
        COUNT(1) as num_games,
        SUM(f1.pts) as subject_points,
        SUM(f2.pts) as object_points
    FROM filtered f1
        JOIN filtered f2
        ON f1.game_id = f2.game_id
        AND f1.player_name <> f2.player_name
    -- 避免重複計算
    WHERE f1.player_id < f2.player_id
        
    GROUP BY 
            f1.player_id,
            f2.player_id,
        CASE WHEN f1.team_abbreviation = f2.team_abbreviation 
            THEN 'shares_team'::edge_type
            ELSE 'plays_against'::edge_type
        END
)

SELECT 
    subject_player_id AS subject_identifier,
    'player'::vertex_type AS subject_type,
    object_player_id AS object_identifier,
    'player'::vertex_type AS object_type,
    edge_type AS edge_type,
    json_build_object(
        'num_games', num_games,
        'subject_points', subject_points,
        'object_points', object_points
    ) AS properties
FROM aggregated

-- 8. Create query for player statistics

SELECT
    v.properties->>'player_name',
    e.object_identifier,
    CAST(v.properties->>'number_of_games' as REAL)/
    CASE WHEN CAST(v.properties->>'total_points' as REAL) = 0 THEN 1
         ELSE CAST(v.properties->>'total_points' as REAL)
    END,
    e.properties->>'num_games' as num_games,
    e.properties->>'subject_points' as subject_points
FROM vertices v JOIN edges e 
    ON v.identifier = e.subject_identifier
    AND v.type = e.subject_type
WHERE e.object_type = 'player'::vertex_type







-- 查詢



--





