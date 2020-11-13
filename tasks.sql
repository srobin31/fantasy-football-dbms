-- register a new user
INSERT INTO user (first_name, last_name, email, password) VALUES ("First", "Last", "first_last@gmail.com", "woahhhh");

-- make a new fantasy league
INSERT INTO league (name, commissioner, num_teams) VALUES ("New League", (SELECT user_id FROM user WHERE email = "first_last@gmail.com"), 10); 

-- add a fantasy team to the newly created league managed by the newly registered user
INSERT INTO fantasy_team (league_id, manager, name, abbreviation) VALUES ((SELECT league_id FROM league WHERE name = "New League"), (SELECT user_id FROM user WHERE email = "first_last@gmail.com"), "Best Team", "BT"); 

-- change a league's is_full attribute to True
UPDATE league l
SET is_full = (
  SELECT 
    count(*) = l.num_teams 
  FROM fantasy_team ft 
    join league l on ft.league_id = l.league_id 
  WHERE 
    l.name = "BCA Fantasy Football"
)
WHERE l.name = "BCA Fantasy Football";

-- release a player from a fantasy team
DELETE
    r
FROM 
    roster r 
    join fantasy_team ft on r.fantasy_team_id = ft.fantasy_team_id 
    join player p on r.player_id = p.player_id 
    join league l on ft.league_id = l.league_id 
    join user u on ft.manager = u.user_id
WHERE 
    l.name = "BCA Fantasy Football" and
    u.email = "matsch@gmail.com" and
    p.first_name = "Alexander" and
    p.last_name = "Mattison" and
    p.nfl_team = "Min" and
    p.position = "RB";

-- add a player to a fantasy team
INSERT INTO roster VALUES (
    (SELECT 
        ft.fantasy_team_id 
    FROM fantasy_team ft 
        join league l on ft.league_id = l.league_id 
        join user u on ft.manager = u.user_id 
    WHERE l.name = "BCA Fantasy Football" and u.email = "matsch@gmail.com"),
    (SELECT 
        p.player_id 
     FROM player p
     WHERE 
        p.first_name = "Derek" and 
        p.last_name = "Carr" and 
        p.position = "QB" and 
        p.nfl_team = "LV")
);

-- complete a trade between 2 fantasy teams
UPDATE
    roster r
    join player p on r.player_id = p.player_id
SET r.fantasy_team_id = (SELECT ft.fantasy_team_id from fantasy_team ft join league l on ft.league_id = l.league_id join user u on ft.manager = u.user_id WHERE l.name = "BCA Fantasy Football" and u.email = "shaduk@gmail.com")
WHERE
    p.first_name = "Alvin" and
    p.last_name = "Kamara" and
    p.position = "RB" and
    p.nfl_team = "NO";

UPDATE
    roster r
    join player p on r.player_id = p.player_id
SET r.fantasy_team_id = (SELECT ft.fantasy_team_id from fantasy_team ft join league l on ft.league_id = l.league_id join user u on ft.manager = u.user_id WHERE l.name = "BCA Fantasy Football" and u.email = "sharob@gmail.com")
WHERE
    p.first_name = "Dalvin" and
    p.last_name = "Cook" and
    p.position = "RB" and
    p.nfl_team = "Min";
    
-- update a player’s NFL team (such as in the event they are traded in real life)
UPDATE
    player p
SET p.nfl_team = "NE"
WHERE 
    p.first_name = "Isaiah" and
    p.last_name = "Ford" and
    p.position = "WR" and
    p.nfl_team = "Mia";
    
-- add a new lineup for a specified fantasy team and week
INSERT INTO 
    weekly_lineup (week, fantasy_team_id)
VALUES
    (2, (SELECT ft.fantasy_team_id FROM fantasy_team ft join league l on ft.league_id = l.league_id join user u on ft.manager = u.user_id WHERE l.name = "BCA Fantasy Football" and u.email = "sharob@gmail.com"));
UPDATE 
    weekly_lineup wl
    join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id
    join league l on ft.league_id = l.league_id 
    join user u on ft.manager = u.user_id  
SET 
    wl.qb = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "QB" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1),
    wl.rb1 = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "RB" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1),
    wl.rb2 = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "RB" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1,1),
    wl.wr1 = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "WR" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1),
    wl.wr2 = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "WR" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1,1),
    wl.te = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "TE" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1),
    wl.flex = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "RB" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 2,1),
    wl.dst = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "DST" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1),
    wl.k = (SELECT p.player_id FROM roster r join player p on r.player_id = p.player_id WHERE p.position = "K" and r.fantasy_team_id = wl.fantasy_team_id LIMIT 1)
WHERE 
    wl.week = 2 and l.name = "BCA Fantasy Football" and u.email = "sharob@gmail.com"; 

-- find how many points the RB2 of a team scored for a given week
SELECT
    (l.py_points * IFNULL(pp.passing_yards, 0) +
    l.ptd_points * IFNULL(pp.passing_tds, 0) +
    l.to_points * IFNULL(pp.turnovers, 0) +
    l.ry_points * IFNULL(pp.rushing_yards, 0) +
    l.rtd_points * IFNULL(pp.rushing_tds, 0) +
    l.rec_points * IFNULL(pp.receptions, 0) +
    l.rey_points * IFNULL(pp.receiving_yards, 0) +
    l.retd_points * IFNULL(pp.receiving_tds, 0) +
    l.sk_points * IFNULL(pp.sacks, 0) +
    l.toc_points * IFNULL(pp.turnovers_created, 0) +
    CASE 
        WHEN pp.points_allowed = 0 THEN l.pa0_points
        WHEN pp.points_allowed >= 1 < 7 THEN l.pa1_points
        WHEN pp.points_allowed >= 7 < 14 THEN l.pa7_points
        WHEN pp.points_allowed >= 14 < 18 THEN l.pa14_points
        WHEN pp.points_allowed >= 28 < 34 THEN l.pa28_points
        WHEN pp.points_allowed >= 35 < 46 THEN l.pa35_points
        WHEN pp.points_allowed >= 46 THEN l.pa46_points
        ELSE 0
    END +
    CASE 
        WHEN pp.yards_allowed < 100 THEN l.ya100_points
        WHEN pp.yards_allowed >= 100 < 200 THEN l.ya199_points
        WHEN pp.yards_allowed >= 200 < 300 THEN l.ya299_points
        WHEN pp.yards_allowed >= 350 < 399 THEN l.ya399_points
        WHEN pp.yards_allowed >= 400 < 450 THEN l.ya449_points
        WHEN pp.yards_allowed >= 450 < 500 THEN l.ya499_points
        WHEN pp.yards_allowed >= 500 < 550 THEN l.ya549_points
        WHEN pp.yards_allowed >= 550 THEN l.ya550_points
        ELSE 0
    END +
    l.fg_points * IFNULL(pp.field_goals, 0) +
    l.mfg_points * IFNULL(pp.missed_field_goals, 0) +
    l.ep_points * IFNULL(pp.extra_points, 0)) as points
FROM
    weekly_lineup wl
    join player p on wl.rb2 = p.player_id
    join player_performance pp on p.player_id = pp.player_id
    join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id
    join league l on ft.league_id = l.league_id
    join user u on ft.manager = u.user_id
WHERE
    l.name = "BCA Fantasy Football" and
    u.email = "sharob@gmail.com" and
    wl.week = 1;
