-- produce a sorted list of Running Backs based on who scored the most 
-- points in the BCA Fantasy Football league Week 1 without any turnovers
-- # of tables joined = 4
-- non-inner/natural join
-- # of ordering fields = 2
-- # of WHERE conditions not for joins = 2
-- non-aggregation functions/expressions in SELECT
-- strong motivation/justification for query in domain
SELECT
    p.nfl_team as Team,
    concat(p.first_name, " ", p.last_name) as Name,
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
    l.ep_points * IFNULL(pp.extra_points, 0)) as Score
FROM
    player_performance pp
    join player p on pp.player_id = p.player_id
    join position pos on p.position = pos.abbreviation
    join league l
WHERE
    pp.week = 1 and
    pp.turnovers = 0 and
    pos.name = "Running Back" and
    l.name = "BCA Fantasy Football"
ORDER BY Score DESC, Team;


-- produce a sorted list of all Quarterbacks and their relevant statistics of everyone who scored 
-- more than 20 points according to BCA Fantasy Football scoring in Week 1 that were not in any 
-- fantasy team lineups sorted by those that had the fewest turnovers and the most passing TDs 
-- # of tables joined = 5
-- non-inner/natural join
-- # of subqueries = 1
-- # of ordering fields = 2
-- strong motivation/justification for query in domain
SELECT
    p.nfl_team as Team,
    concat(p.first_name, " ", p.last_name) as Name,
    pp.passing_yards as PassingYards,
    pp.passing_tds as PassingTDs,
    pp.rushing_yards as RushingYards,
    pp.rushing_tds as RushingTDs,
    pp.turnovers as Turnovers
FROM
    player_performance pp
    join player p on pp.player_id = p.player_id
    join position pos on p.position = pos.abbreviation
    left join weekly_lineup wl on wl.qb = p.player_id
    cross join league l
WHERE
    pp.week = 1 and
    pos.name = "Quarterback" and
    l.name = "BCA Fantasy Football" and
    p.player_id not in (SELECT qb FROM weekly_lineup) and
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
    l.ep_points * IFNULL(pp.extra_points, 0)) > 20
 ORDER BY Turnovers ASC, PassingTDs DESC;

-- find how many Running Backs and Wide Receivers each fantasy team in BCA Fantasy Football has
-- # of tables joined = 4
-- # of subqueries = 1
-- aggregate function
-- grouping
-- # of ordering fields = 2
SELECT
    ft.name as TeamName,
    p.position as Position,
    count(*) as PlayerCount
FROM
    roster r
    join player p on r.player_id = p.player_id
    join fantasy_team ft on r.fantasy_team_id = ft.fantasy_team_id
    join league l on ft.league_id = l.league_id
WHERE
    l.name = "BCA Fantasy Football" and
    p.position in (SELECT abbreviation FROM position WHERE name in ('Running Back', 'Wide Receiver'))
GROUP BY ft.fantasy_team_id, p.position
ORDER BY PlayerCount DESC, TeamName;

-- find which Fantasy Teams have more than 2 players with the same bye week from any NFL team, 
-- including how many players on the fantasy team have that bye week
-- # of tables joined = 4
-- aggregate function
-- grouping
-- # of ordering fields = 3
-- strong motivation/justification for the query in domain
SELECT
    ft.name as TeamName,
    t.bye_week as ByeWeek,
    count(*) as PlayerCount
FROM
    roster r
    join fantasy_team ft on r.fantasy_team_id = ft.fantasy_team_id
    join player p on r.player_id = p.player_id
    join nfl_team t on p.nfl_team = t.abbreviation
GROUP BY ft.fantasy_team_id, t.bye_week
HAVING PlayerCount > 2
ORDER BY ByeWeek, PlayerCount Desc, TeamName;

-- find all the players on the Week 1 lineup of the team in BCA Fantasy Football 
-- managed by the user with email bencos@gmail.com along with their score
-- # of tables joined = 3, 4 (subquery)
-- non-inner/natural join
-- # of subqueries > 2
-- # of queries comprising result via union > 1
-- # of ordering fields = 2
-- strong motivation/justification for the query in the domain
SELECT
    p.position as Position,
    concat(p.first_name, " ", p.last_name) as Name,
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
    l.ep_points * IFNULL(pp.extra_points, 0)) as Score
FROM
  player p
    join player_performance pp on p.player_id = pp.player_id
    cross join league l
WHERE 
    pp.week = 1 and
    l.name = "BCA Fantasy Football" and
    p.player_id in
      (SELECT wl.qb as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.rb1 as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.rb2 as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.wr1 as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.wr2 as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.te as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.flex as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.dst as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com"
      UNION
      SELECT wl.k as starter FROM weekly_lineup wl join fantasy_team ft on wl.fantasy_team_id = ft.fantasy_team_id join user u on ft.manager = u.user_id join league l on ft.league_id = l.league_id WHERE wl.week = 1 and l.name = "BCA Fantasy Football" and u.email = "bencos@gmail.com")
ORDER BY FIELD(p.position, "QB", "RB", "WR", "TE", "D/ST", "K"), Score DESC;
 