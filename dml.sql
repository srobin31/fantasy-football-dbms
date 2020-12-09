CREATE VIEW player_score AS
SELECT
	week,
	player_id,
	SUM(quantity*points) as score
FROM player_performance pp
	join scoring s on pp.statistic = s.abbreviation
GROUP BY
	week, player_id;

CREATE VIEW lineup_score AS
SELECT
	l.*,
	ps.score
FROM
	lineup l
	join player_score ps on (l.player_id = ps.player_id and l.week = ps.week);

CREATE VIEW matchup_score AS
SELECT
	h.matchup_id,
	h.week,
	home_team,
	away_team,
	home_team_score,
	away_team_score,
	IF (home_team_score >= away_team_score, home_team, away_team) as winner,
	IF (home_team_score < away_team_score, home_team, away_team) as loser
FROM
	(SELECT
			m.matchup_id,
			m.week,
			m.home_team as home_team,
			SUM(score) as home_team_score
	FROM
			matchup m
			join lineup_score ls on m.week = ls.week AND m.home_team = ls.fantasy_team_id
			join lineup_position lp on ls.position_slot = lp.lineup_posn_id
	WHERE
			lp.abbreviation <> "BE"
	GROUP BY m.week, ls.fantasy_team_id) h
	join
	(SELECT
			m.matchup_id,
			m.week,
			m.away_team,
			SUM(score) as away_team_score
	FROM
			matchup m
			join lineup_score ls on m.week = ls.week AND m.away_team = ls.fantasy_team_id
			join lineup_position lp on ls.position_slot = lp.lineup_posn_id
	WHERE
			lp.abbreviation <> "BE"
	GROUP BY m.week, ls.fantasy_team_id) a
	on h.matchup_id = a.matchup_id
ORDER BY matchup_id;

CREATE PROCEDURE insert_user(fname VARCHAR(20), lname VARCHAR(30), email VARCHAR(50), password VARCHAR(50))
BEGIN
	DECLARE salt VARCHAR(6) DEFAULT SUBSTRING(SHA1(RAND()), 1, 6);
	DECLARE hash VARCHAR(40) DEFAULT SHA1(CONCAT(salt, password));
	INSERT INTO user (first_name, last_name, email, password) VALUES (fname, lname, email, CONCAT(salt, hash));
END;

CREATE TRIGGER fantasy_team_insert AFTER INSERT on fantasy_team
	FOR EACH ROW
		BEGIN
			UPDATE league SET num_teams = num_teams + 1 WHERE league_id = NEW.league_id;
		END;

CREATE PROCEDURE add_fantasy_team(l_id INT, m_id INT, name VARCHAR(30), abbreviation VARCHAR(4))
BEGIN
	IF (SELECT is_full from league WHERE league_id = l_id) THEN
		SELECT CONCAT("League ", l_id, " is full.") as ERROR;
	ELSE
		INSERT INTO fantasy_team (league_id, manager, name, abbreviation) VALUES (l_id, m_id, name, abbreviation);
	END IF;
END;

CREATE TRIGGER roster_insert AFTER INSERT on roster
	FOR EACH ROW
		BEGIN
			UPDATE fantasy_team SET roster_size = roster_size + 1 WHERE fantasy_team_id = NEW.fantasy_team_id;
		END;

CREATE TRIGGER roster_delete AFTER DELETE on roster
	FOR EACH ROW
		BEGIN
			UPDATE fantasy_team SET roster_size = roster_size - 1 WHERE fantasy_team_id = OLD.fantasy_team_id;
		END;

CREATE PROCEDURE add_player(ft_id INT, p_id INT)
BEGIN
	IF (SELECT roster_full FROM fantasy_team WHERE fantasy_team_id = ft_id) THEN
		SELECT CONCAT("Fantasy team ", ft_id, " roster is full.") as ERROR;
	ELSE
		INSERT INTO roster (fantasy_team_id, player_id) VALUES (ft_id, p_id);
	END IF;
END;

CREATE PROCEDURE roster_transaction(ft_id INT, dropped_pid INT, added_pid INT)
BEGIN
	DELETE r FROM roster r join player p on r.player_id = p.player_id WHERE r.fantasy_team_id = ft_id and r.player_id = dropped_pid;
	INSERT INTO roster (fantasy_team_id, player_id) VALUES (ft_id, added_pid);
END;

CREATE PROCEDURE update_lineup(w INT, ft_id INT, pos INT, p_id INT)
BEGIN
	IF (SELECT
			(SELECT position FROM lineup_position WHERE lineup_posn_id = pos) =
			(SELECT position FROM player WHERE player_id = p_id))
	THEN
		INSERT INTO lineup (week, fantasy_team_id, position_slot, player_id) VALUES (w, ft_id, pos, p_id);
	ELSE
		SELECT CONCAT("Player ", p_id, "'s position does not match position slot ", pos) as ERROR;
	END IF;
END;

CALL insert_user("Shawn", "Robin", "sharob@gmail.com", "password");
CALL insert_user("Daniel", "Ryvkin", "danryv@gamil.com", "p@ssword");
CALL insert_user("Kaito", "Higashi", "kaihig@gmail.com", "passw0rd");
CALL insert_user("Shalom", "Dukhande", "shaduk@gmail.com", "PaSsWoRd");
CALL insert_user("Matthew", "Schwarz", "matsch@gmail.com", "PA55WORD");
CALL insert_user("Benjamin", "Costa", "bencos@gmail.com", "P4SSWORD");
CALL insert_user("Michael", "Grossman", "micgro@gmail.com", "GoDolphins");
CALL insert_user("Matt", "Teshome", "mattes@gmail.com", "BearsFan1234");
CALL insert_user("Jared", "Tarabocchia", "jartar@gmail.com", "hunter2");
CALL insert_user("Justin", "Jung", "jusjun@gmail.com", "password");

INSERT INTO
	league (name, commissioner, max_teams)
VALUES
	("BCA Fantasy Football", 4, 10),
	("BCA FF", 6, 8),
	("Rutherford FF", 1, 10),
	("Mahwah FF", 2, 10),
	("Hasbrouck Heights FF", 4, 10),
	("Wyckoff FF", 7, 12),
	("Dumont Fantasy Football", 4, 6),
	("Saddle Brook FF", 8, 10),
	("Cliffside Park FF", 9, 8),
	("NEU Fantasy Football", 1, 10);

CALL add_fantasy_team(1, 1, "Team Robin", "SR");
CALL add_fantasy_team(1, 2, "Team Ryv", "RYV");
CALL add_fantasy_team(1, 3, "Team Higashi", "KH");
CALL add_fantasy_team(1, 4, "Team Shalman", "DUKH");
CALL add_fantasy_team(1, 5, "Take Down Shalom", "SCHW");
CALL add_fantasy_team(1, 6, "Team Costa", "COST");
CALL add_fantasy_team(1, 7, "Team Grossman", "MG");
CALL add_fantasy_team(1, 8, "Team Teshome", "TESH");
CALL add_fantasy_team(1, 9, "Team JarTar", "JT");
CALL add_fantasy_team(1, 10, "Team Jung", "JJ");

INSERT INTO
	`position` (abbreviation, name)
VALUES
	("QB", "Quarterback"),
	("RB", "Running Back"),
	("WR", "Wide Receiver"),
	("TE", "Tight End"),
	("D/ST", "Defense/Special Teams"),
	("K", "Kicker"),
	("DL", "Defensive Line"),
	("LB", "Linebacker"),
	("CB", "Cornerback"),
	("S", "Safety");

INSERT INTO
	nfl_team (abbreviation, city, name, bye_week)
VALUES
	("ARI", "Arizona", "Cardinals", 8),
	("ATL", "Atlanta", "Falcons", 10),
	("BAL", "Baltimore", "Ravens", 7),
	("BUF", "Buffalo", "Bills", 11),
	("CAR", "Carolina", "Panthers", 13),
	("CHI", "Chicago", "Bears", 11),
	("CIN", "Cincinnati", "Bengals", 9),
	("CLE", "Cleveland", "Browns", 9),
	("DAL", "Dallas", "Cowboys", 10),
	("DEN", "Denver", "Broncos", 5),
	("DET", "Detroit", "Lions", 5),
	("GB", "Green Bay", "Packers", 5),
	("HOU", "Houston", "Texans", 8),
	("IND", "Indianapolis", "Colts", 7),
	("JAX", "Jacksonville", "Jaguars", 8),
	("KC", "Kansas City", "Chiefs", 10),
	("LV", "Las Vegas", "Raiders", 6),
	("LAC", "Los Angeles", "Chargers", 6),
	("LAR", "Los Angeles", "Rams", 9),
	("MIA", "Miami", "Dolphins", 7),
	("MIN", "Minnesota", "Vikings", 7),
	("NE", "New England", "Patriots", 5),
	("NO", "New Orleans", "Saints", 6),
	("NYJ", "New York", "Jets", 10),
	("NYG", "New York", "Giants", 11),
	("PHI", "Philadelphia", "Eagles", 9),
	("PIT", "Pittsburgh", "Steelers", 4),
	("SF", "San Francisco", "49ers", 11),
	("SEA", "Seattle", "Seahawks", 6),
	("TB", "Tamba Bay", "Buccaneers", 13),
	("TEN", "Tennessee", "Titans", 4),
	("WSH", "Washington", "Football Team", 8);

INSERT INTO
	player (first_name, last_name, position, nfl_team)
VALUES
	('Christian', 'McCaffrey', 'RB', 'CAR'),
	('Ezekiel', 'Elliott', 'RB', 'DAL'),
	('Saquon', 'Barkley', 'RB', 'NYG'),
	('Alvin', 'Kamara', 'RB', 'NO'),
	('Dalvin', 'Cook', 'RB', 'MIN'),
	('Derrick', 'Henry', 'RB', 'TEN'),
	('Clyde', 'Edwards-Helaire', 'RB', 'KC'),
	('Michael', 'Thomas', 'WR', 'NO'),
	('Josh', 'Jacobs', 'RB', 'LV'),
	('Nick', 'Chubb', 'RB', 'CLE'),
	('DeAndre', 'Hopkins', 'WR', 'ARI'),
	('Kenyan', 'Drake', 'RB', 'ARI'),
	('Aaron', 'Jones', 'RB', 'GB'),
	('Miles', 'Sanders', 'RB', 'PHI'),
	('Davante', 'Adams', 'WR', 'GB'),
	('Julio', 'Jones', 'WR', 'ATL'),
	('Tyreek', 'Hill', 'WR', 'KC'),
	('Austin', 'Ekeler', 'RB', 'LAC'),
	('Chris', 'Godwin', 'WR', 'TB'),
	('Joe', 'Mixon', 'RB', 'CIN'),
	('Travis', 'Kelce', 'TE', 'KC'),
	('George', 'Kittle', 'TE', 'SF'),
	('Lamar', 'Jackson', 'QB', 'BAL'),
	('Mike', 'Evans', 'WR', 'TB'),
	('Patrick', 'Mahomes', 'QB', 'KC'),
	('Adam', 'Thielen', 'WR', 'MIN'),
	('Odell', 'Beckham Jr.', 'WR', 'CLE'),
	('Dak', 'Prescott', 'QB', 'DAL'),
	('Kenny', 'Golladay', 'WR', 'DET'),
	('DJ', 'Moore', 'WR', 'CAR'),
	('Todd', 'Gurley II', 'RB', 'ATL'),
	('Courtland', 'Sutton', 'WR', 'DEN'),
	('Chris', 'Carson', 'RB', 'SEA'),
	('A.J.', 'Brown', 'WR', 'TEN'),
	('David', 'Johnson', 'RB', 'HOU'),
	('James', 'Conner', 'RB', 'PIT'),
	('Amari', 'Cooper', 'WR', 'DAL'),
	('Mark', 'Andrews', 'TE', 'BAL'),
	("Le'Veon", 'Bell', 'RB', 'KC'),
	('Allen', 'Robinson II', 'WR', 'CHI'),
	('JuJu', 'Smith-Schuster', 'WR', 'PIT'),
	('Tyler', 'Lockett', 'WR', 'SEA'),
	('Calvin', 'Ridley', 'WR', 'ATL'),
	('Zach', 'Ertz', 'TE', 'PHI'),
	('Terry', 'McLaurin', 'WR', 'WSH'),
	('Robert', 'Woods', 'WR', 'LAR'),
	('Deshaun', 'Watson', 'QB', 'HOU'),
	('Melvin', 'Gordon III', 'RB', 'DEN'),
	('Cooper', 'Kupp', 'WR', 'LAR'),
	('Jonathan', 'Taylor', 'RB', 'IND'),
	('Jarvis', 'Landry', 'WR', 'CLE'),
	('Russell', 'Wilson', 'QB', 'SEA'),
	('Darren', 'Waller', 'TE', 'LV'),
	('T.Y.', 'Hilton', 'WR', 'IND'),
	('Evan', 'Engram', 'TE', 'NYG'),
	('Devin', 'Singletary', 'RB', 'BUF'),
	('Cam', 'Akers', 'RB', 'LAR'),
	('Keenan', 'Allen', 'WR', 'LAC'),
	('DJ', 'Chark Jr.', 'WR', 'JAX'),
	('Kyler', 'Murray', 'QB', 'ARI'),
	('Kareem', 'Hunt', 'RB', 'CLE'),
	("D'Andre", 'Swift', 'RB', 'DET'),
	('DK', 'Metcalf', 'WR', 'SEA'),
	('Raheem', 'Mostert', 'RB', 'SF'),
	('Tyler', 'Higbee', 'TE', 'LAR'),
	('Tom', 'Brady', 'QB', 'TB'),
	('Will', 'Fuller V', 'WR', 'HOU'),
	('DeVante', 'Parker', 'WR', 'MIA'),
	('Leonard', 'Fournette', 'RB', 'TB'),
	('James', 'White', 'RB', 'NE'),
	('Jared', 'Cook', 'TE', 'NO'),
	('Marquise', 'Brown', 'WR', 'BAL'),
	('A.J.', 'Green', 'WR', 'CIN'),
	('Antonio', 'Gibson', 'RB', 'WSH'),
	('David', 'Montgomery', 'RB', 'CHI'),
	('Stefon', 'Diggs', 'WR', 'BUF'),
	('Sterling', 'Shepard', 'WR', 'NYG'),
	('Tyler', 'Boyd', 'WR', 'CIN'),
	('Mark', 'Ingram II', 'RB', 'BAL'),
	('Michael', 'Gallup', 'WR', 'DAL'),
	('Deebo', 'Samuel', 'WR', 'SF'),
	('Josh', 'Allen', 'QB', 'BUF'),
	('Tarik', 'Cohen', 'RB', 'CHI'),
	('Matt', 'Ryan', 'QB', 'ATL'),
	('Kerryon', 'Johnson', 'RB', 'DET'),
	('Julian', 'Edelman', 'WR', 'NE'),
	('Jordan', 'Howard', 'RB', 'MIA'),
	('Brandin', 'Cooks', 'WR', 'HOU'),
	('Henry', 'Ruggs III', 'WR', 'LV'),
	('Marvin', 'Jones Jr.', 'WR', 'DET'),
	('Drew', 'Brees', 'QB', 'NO'),
	('Rob', 'Gronkowski', 'TE', 'TB'),
	('J.K.', 'Dobbins', 'RB', 'BAL'),
	('DeSean', 'Jackson', 'WR', 'PHI'),
	('Harrison', 'Butker', 'K', 'KC'),
	('Steelers', 'D/ST', 'D/ST', 'PIT'),
	('Ronald', 'Jones II', 'RB', 'TB'),
	('Wil', 'Lutz', 'K', 'NO'),
	('Jamison', 'Crowder', 'WR', 'NYJ'),
	('Diontae', 'Johnson', 'WR', 'PIT'),
	('Phillip', 'Lindsay', 'RB', 'DEN'),
	('Hunter', 'Henry', 'TE', 'LAC'),
	('Patriots', 'D/ST', 'D/ST', 'NE'),
	('Matt', 'Breida', 'RB', 'MIA'),
	('Jerry', 'Jeudy', 'WR', 'DEN'),
	('Ravens', 'D/ST', 'D/ST', 'BAL'),
	('Bills', 'D/ST', 'D/ST', 'BUF'),
	('49ers', 'D/ST', 'D/ST', 'SF'),
	('Noah', 'Fant', 'TE', 'DEN'),
	('Golden', 'Tate', 'WR', 'NYG'),
	('Zack', 'Moss', 'RB', 'BUF'),
	('Preston', 'Williams', 'WR', 'MIA'),
	('CeeDee', 'Lamb', 'WR', 'DAL'),
	('Mike', 'Gesicki', 'TE', 'MIA'),
	('Christian', 'Kirk', 'WR', 'ARI'),
	('T.J.', 'Hockenson', 'TE', 'DET'),
	('Emmanuel', 'Sanders', 'WR', 'NO'),
	('Darrell', 'Henderson Jr.', 'RB', 'LAR'),
	('Vikings', 'D/ST', 'D/ST', 'MIN'),
	('Darius', 'Slayton', 'WR', 'NYG'),
	('Robby', 'Anderson', 'WR', 'CAR'),
	('Carson', 'Wentz', 'QB', 'PHI'),
	('John', 'Brown', 'WR', 'BUF'),
	('Colts', 'D/ST', 'D/ST', 'IND'),
	('Justin', 'Tucker', 'K', 'BAL'),
	('Aaron', 'Rodgers', 'QB', 'GB'),
	('Ryan', 'Succop', 'K', 'TB'),
	('Matt', 'Prater', 'K', 'DET'),
	('Daniel', 'Jones', 'QB', 'NYG'),
	('Saints', 'D/ST', 'D/ST', 'NO'),
	('Matthew', 'Stafford', 'QB', 'DET'),
	('Bears', 'D/ST', 'D/ST', 'CHI'),
	('Hayden', 'Hurst', 'TE', 'ATL'),
	('Darrel', 'Williams', 'RB', 'KC'),
	('Marlon', 'Mack', 'RB', 'IND'),
	('Cam', 'Newton', 'QB', 'NE'),
	('Ben', 'Roethlisberger', 'QB', 'PIT'),
	('Duke', 'Johnson', 'RB', 'HOU'),
	('Mike', 'Williams', 'WR', 'LAC'),
	('Tevin', 'Coleman', 'RB', 'SF'),
	('Broncos', 'D/ST', 'D/ST', 'DEN'),
	('Buccaneers', 'D/ST', 'D/ST', 'TB'),
	('Alexander', 'Mattison', 'RB', 'MIN'),
	('Cowboys', 'D/ST', 'D/ST', 'DAL'),
	('Latavius', 'Murray', 'RB', 'NO'),
	('Sony', 'Michel', 'RB', 'NE'),
	("N'Keal", 'Harry', 'WR', 'NE'),
	('Joe', 'Burrow', 'QB', 'CIN'),
	('Chris', 'Thompson', 'RB', 'JAX'),
	('Greg', 'Zuerlein', 'K', 'DAL'),
	('Mecole', 'Hardman', 'WR', 'KC'),
	("Ka'imi", 'Fairbairn', 'K', 'HOU'),
	('Jack', 'Doyle', 'TE', 'IND'),
	('Justin', 'Jefferson', 'WR', 'MIN'),
	('Titans', 'D/ST', 'D/ST', 'TEN'),
	('Seahawks', 'D/ST', 'D/ST', 'SEA'),
	('Zane', 'Gonzalez', 'K', 'ARI'),
	('Breshad', 'Perriman', 'WR', 'NYJ'),
	('Chris', 'Boswell', 'K', 'PIT'),
	('Robbie', 'Gould', 'K', 'SF'),
	('Derek', 'Carr', 'QB', 'LV'),
	('Eagles', 'D/ST', 'D/ST', 'PHI'),
	('Isaiah', 'Ford', 'WR', 'MIA'),
	('Cardinals', 'D/ST', 'D/ST', 'ARI'),
	('Chiefs', 'D/ST', 'D/ST', 'KC'),
	('Mason', 'Crosby', 'K', 'GB'),
	('Malcolm', 'Brown', 'RB', 'LAR'),
	('Myles', 'Gaskin', 'RB', 'MIA'),
	('James', 'Robinson', 'RB', 'JAX'),
	('Nyheim', 'Hines', 'RB', 'IND'),
	('Sammy', 'Watkins', 'WR', 'KC'),
	('Dallas', 'Goedert', 'TE', 'PHI'),
	('Parris', 'Campbell', 'WR', 'IND'),
	('Football Team', 'D/ST', 'D/ST', 'WSH'),
	('Scotty', 'Miller', 'WR', 'TB'),
	('Adrian', 'Peterson', 'RB', 'DET'),
	('Mike', 'Davis', 'RB', 'CAR'),
	('Joshua', 'Kelley', 'RB', 'LAC'),
	('Jonnu', 'Smith', 'TE', 'TEN'),
	('Jerick', 'McKinnon', 'RB', 'SF'),
	('Younghoe', 'Koo', 'K', 'ATL'),
	('Devonta', 'Freeman', 'RB', 'NYG'),
	('Giants', 'D/ST', 'D/ST', 'NYG'),
	('Gardner', 'Minshew II', 'QB', 'JAX'),
	('Dalton', 'Schultz', 'TE', 'DAL'),
	('Browns', 'D/ST', 'D/ST', 'CLE'),
	('Russell', 'Gage', 'WR', 'ATL'),
	('Justin', 'Herbert', 'QB', 'LAC'),
	("Tre'Quan", 'Smith', 'WR', 'NO');

CALL add_player(1, 4);
CALL add_player(1, 17);
CALL add_player(1, 24);
CALL add_player(1, 37);
CALL add_player(1, 44);
CALL add_player(1, 57);
CALL add_player(1, 64);
CALL add_player(1, 77);
CALL add_player(1, 84);
CALL add_player(1, 97);
CALL add_player(1, 104);
CALL add_player(1, 117);
CALL add_player(1, 124);
CALL add_player(1, 137);
CALL add_player(1, 144);
CALL add_player(1, 157);
CALL add_player(2, 6);
CALL add_player(2, 15);
CALL add_player(2, 26);
CALL add_player(2, 35);
CALL add_player(2, 46);
CALL add_player(2, 55);
CALL add_player(2, 66);
CALL add_player(2, 75);
CALL add_player(2, 86);
CALL add_player(2, 95);
CALL add_player(2, 106);
CALL add_player(2, 115);
CALL add_player(2, 126);
CALL add_player(2, 135);
CALL add_player(2, 146);
CALL add_player(2, 155);
CALL add_player(3, 9);
CALL add_player(3, 12);
CALL add_player(3, 29);
CALL add_player(3, 32);
CALL add_player(3, 49);
CALL add_player(3, 52);
CALL add_player(3, 69);
CALL add_player(3, 72);
CALL add_player(3, 89);
CALL add_player(3, 92);
CALL add_player(3, 109);
CALL add_player(3, 112);
CALL add_player(3, 129);
CALL add_player(3, 132);
CALL add_player(3, 149);
CALL add_player(3, 152);
CALL add_player(4, 5);
CALL add_player(4, 16);
CALL add_player(4, 25);
CALL add_player(4, 36);
CALL add_player(4, 45);
CALL add_player(4, 56);
CALL add_player(4, 65);
CALL add_player(4, 76);
CALL add_player(4, 85);
CALL add_player(4, 96);
CALL add_player(4, 105);
CALL add_player(4, 116);
CALL add_player(4, 125);
CALL add_player(4, 136);
CALL add_player(4, 145);
CALL add_player(4, 156);
CALL add_player(5, 3);
CALL add_player(5, 18);
CALL add_player(5, 23);
CALL add_player(5, 38);
CALL add_player(5, 43);
CALL add_player(5, 58);
CALL add_player(5, 63);
CALL add_player(5, 78);
CALL add_player(5, 83);
CALL add_player(5, 98);
CALL add_player(5, 103);
CALL add_player(5, 118);
CALL add_player(5, 123);
CALL add_player(5, 138);
CALL add_player(5, 143);
CALL add_player(5, 158);
CALL add_player(6, 10);
CALL add_player(6, 11);
CALL add_player(6, 30);
CALL add_player(6, 31);
CALL add_player(6, 50);
CALL add_player(6, 51);
CALL add_player(6, 70);
CALL add_player(6, 71);
CALL add_player(6, 90);
CALL add_player(6, 91);
CALL add_player(6, 110);
CALL add_player(6, 111);
CALL add_player(6, 130);
CALL add_player(6, 131);
CALL add_player(6, 150);
CALL add_player(6, 151);
CALL add_player(7, 2);
CALL add_player(7, 19);
CALL add_player(7, 22);
CALL add_player(7, 39);
CALL add_player(7, 42);
CALL add_player(7, 59);
CALL add_player(7, 62);
CALL add_player(7, 79);
CALL add_player(7, 82);
CALL add_player(7, 99);
CALL add_player(7, 102);
CALL add_player(7, 119);
CALL add_player(7, 122);
CALL add_player(7, 139);
CALL add_player(7, 142);
CALL add_player(7, 159);
CALL add_player(8, 1);
CALL add_player(8, 20);
CALL add_player(8, 21);
CALL add_player(8, 40);
CALL add_player(8, 41);
CALL add_player(8, 60);
CALL add_player(8, 61);
CALL add_player(8, 80);
CALL add_player(8, 81);
CALL add_player(8, 100);
CALL add_player(8, 101);
CALL add_player(8, 120);
CALL add_player(8, 121);
CALL add_player(8, 140);
CALL add_player(8, 141);
CALL add_player(8, 160);
CALL add_player(9, 8);
CALL add_player(9, 13);
CALL add_player(9, 28);
CALL add_player(9, 33);
CALL add_player(9, 48);
CALL add_player(9, 53);
CALL add_player(9, 68);
CALL add_player(9, 73);
CALL add_player(9, 88);
CALL add_player(9, 93);
CALL add_player(9, 108);
CALL add_player(9, 113);
CALL add_player(9, 128);
CALL add_player(9, 133);
CALL add_player(9, 148);
CALL add_player(9, 153);
CALL add_player(10, 7);
CALL add_player(10, 14);
CALL add_player(10, 27);
CALL add_player(10, 34);
CALL add_player(10, 47);
CALL add_player(10, 54);
CALL add_player(10, 67);
CALL add_player(10, 74);
CALL add_player(10, 87);
CALL add_player(10, 94);
CALL add_player(10, 107);
CALL add_player(10, 114);
CALL add_player(10, 127);
CALL add_player(10, 134);
CALL add_player(10, 147);
CALL add_player(10, 154);

INSERT INTO
	lineup_position (abbreviation, `position`, slot_description)
VALUES
	("QB", "QB", "Quarterback"),
	("RB1", "RB", "Running Back 1"),
	("RB2", "RB", "Running Back 2"),
	("WR1", "WR", "Wide Receiver 1"),
	("WR2", "WR", "Wide Receiver 2"),
	("TE", "TE", "Tight End"),
	("FLEX", "RB", "Flex (RB)"),
	("FLEX", "WR", "Flex (WR)"),
	("FLEX", "TE", "Flex (TE)"),
	("D/ST", "D/ST", "Defense / Special Teams"),
	("K", "K", "Kicker"),
	("BE", "QB", "Bench Quarterback"),
	("BE", "RB", "Bench Running Back"),
	("BE", "WR", "Bench Wide Receiver"),
	("BE", "TE", "Bench Tight End"),
	("BE", "D/ST", "Bench Defense / Special Teams"),
	("BE", "K", "Bench Kicker");

CALL update_lineup(1, 1, 1, 84);
CALL update_lineup(1, 1, 2, 4);
CALL update_lineup(1, 1, 3, 64);
CALL update_lineup(1, 1, 4, 17);
CALL update_lineup(1, 1, 5, 37);
CALL update_lineup(1, 1, 6, 44);
CALL update_lineup(1, 1, 8, 24);
CALL update_lineup(1, 1, 10, 124);
CALL update_lineup(1, 1, 11, 157);
CALL update_lineup(1, 2, 1, 66);
CALL update_lineup(1, 2, 2, 6);
CALL update_lineup(1, 2, 3, 35);
CALL update_lineup(1, 2, 4, 15);
CALL update_lineup(1, 2, 5, 26);
CALL update_lineup(1, 2, 6, 55);
CALL update_lineup(1, 2, 8, 46);
CALL update_lineup(1, 2, 10, 106);
CALL update_lineup(1, 2, 11, 95);
CALL update_lineup(1, 3, 1, 52);
CALL update_lineup(1, 3, 2, 9);
CALL update_lineup(1, 3, 3, 12);
CALL update_lineup(1, 3, 4, 49);
CALL update_lineup(1, 3, 5, 72);
CALL update_lineup(1, 3, 6, 92);
CALL update_lineup(1, 3, 8, 89);
CALL update_lineup(1, 3, 10, 132);
CALL update_lineup(1, 3, 11, 152);
CALL update_lineup(1, 4, 1, 25);
CALL update_lineup(1, 4, 2, 5);
CALL update_lineup(1, 4, 3, 36);
CALL update_lineup(1, 4, 4, 16);
CALL update_lineup(1, 4, 5, 45);
CALL update_lineup(1, 4, 6, 65);
CALL update_lineup(1, 4, 7, 56);
CALL update_lineup(1, 4, 10, 96);
CALL update_lineup(1, 4, 11, 125);
CALL update_lineup(1, 5, 1, 23);
CALL update_lineup(1, 5, 2, 3);
CALL update_lineup(1, 5, 3, 18);
CALL update_lineup(1, 5, 4, 43);
CALL update_lineup(1, 5, 5, 58);
CALL update_lineup(1, 5, 6, 38);
CALL update_lineup(1, 5, 8, 63);
CALL update_lineup(1, 5, 10, 103);
CALL update_lineup(1, 5, 11, 98);
CALL update_lineup(1, 6, 1, 91);
CALL update_lineup(1, 6, 2, 10);
CALL update_lineup(1, 6, 3, 31);
CALL update_lineup(1, 6, 4, 11);
CALL update_lineup(1, 6, 5, 30);
CALL update_lineup(1, 6, 6, 71);
CALL update_lineup(1, 6, 7, 50);
CALL update_lineup(1, 6, 10, 130);
CALL update_lineup(1, 6, 11, 150);
CALL update_lineup(1, 7, 1, 82);
CALL update_lineup(1, 7, 2, 2);
CALL update_lineup(1, 7, 3, 39);
CALL update_lineup(1, 7, 4, 19);
CALL update_lineup(1, 7, 5, 42);
CALL update_lineup(1, 7, 6, 22);
CALL update_lineup(1, 7, 8, 59);
CALL update_lineup(1, 7, 10, 119);
CALL update_lineup(1, 7, 11, 159);
CALL update_lineup(1, 8, 1, 60);
CALL update_lineup(1, 8, 2, 1);
CALL update_lineup(1, 8, 3, 20);
CALL update_lineup(1, 8, 4, 40);
CALL update_lineup(1, 8, 5, 41);
CALL update_lineup(1, 8, 6, 21);
CALL update_lineup(1, 8, 7, 61);
CALL update_lineup(1, 8, 10, 162);
CALL update_lineup(1, 8, 11, 160);
CALL update_lineup(1, 9, 1, 28);
CALL update_lineup(1, 9, 2, 13);
CALL update_lineup(1, 9, 3, 33);
CALL update_lineup(1, 9, 4, 8);
CALL update_lineup(1, 9, 5, 68);
CALL update_lineup(1, 9, 6, 53);
CALL update_lineup(1, 9, 7, 48);
CALL update_lineup(1, 9, 10, 108);
CALL update_lineup(1, 9, 11, 128);
CALL update_lineup(1, 10, 1, 47);
CALL update_lineup(1, 10, 2, 7);
CALL update_lineup(1, 10, 3, 74);
CALL update_lineup(1, 10, 4, 27);
CALL update_lineup(1, 10, 5, 34);
CALL update_lineup(1, 10, 6, 114);
CALL update_lineup(1, 10, 8, 54);
CALL update_lineup(1, 10, 10, 107);
CALL update_lineup(1, 10, 11, 127);
CALL update_lineup(2, 1, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Matt Ryan"));
CALL update_lineup(2, 1, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Alvin Kamara"));
CALL update_lineup(2, 1, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Raheem Mostert"));
CALL update_lineup(2, 1, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tyreek Hill"));
CALL update_lineup(2, 1, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Evans"));
CALL update_lineup(2, 1, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Zach Ertz"));
CALL update_lineup(2, 1, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Amari Cooper"));
CALL update_lineup(2, 1, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Colts D/ST"));
CALL update_lineup(2, 1, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Zane Gonzalez"));
CALL update_lineup(2, 2, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tom Brady"));
CALL update_lineup(2, 2, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Derrick Henry"));
CALL update_lineup(2, 2, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "David Johnson"));
CALL update_lineup(2, 2, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Davante Adams"));
CALL update_lineup(2, 2, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Adam Thielen"));
CALL update_lineup(2, 2, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Evan Engram"));
CALL update_lineup(2, 2, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Robert Woods"));
CALL update_lineup(2, 2, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Ravens D/ST"));
CALL update_lineup(2, 2, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Harrison Butker"));
CALL update_lineup(2, 3, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Russell Wilson"));
CALL update_lineup(2, 3, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Josh Jacobs"));
CALL update_lineup(2, 3, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kenyan Drake"));
CALL update_lineup(2, 3, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Courtland Sutton"));
CALL update_lineup(2, 3, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Marquise Brown"));
CALL update_lineup(2, 3, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Noah Fant"));
CALL update_lineup(2, 3, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Cooper Kupp"));
CALL update_lineup(2, 3, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Bears D/ST"));
CALL update_lineup(2, 3, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mason Crosby"));
CALL update_lineup(2, 4, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Patrick Mahomes"));
CALL update_lineup(2, 4, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Dalvin Cook"));
CALL update_lineup(2, 4, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "James Conner"));
CALL update_lineup(2, 4, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Julio Jones"));
CALL update_lineup(2, 4, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Terry McLaurin"));
CALL update_lineup(2, 4, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tyler Higbee"));
CALL update_lineup(2, 4, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Stefon Diggs"));
CALL update_lineup(2, 4, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Steelers D/ST"));
CALL update_lineup(2, 4, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Justin Tucker"));
CALL update_lineup(2, 5, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Lamar Jackson"));
CALL update_lineup(2, 5, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Saquon Barkley"));
CALL update_lineup(2, 5, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Austin Ekeler"));
CALL update_lineup(2, 5, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Calvin Ridley"));
CALL update_lineup(2, 5, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Keenan Allen"));
CALL update_lineup(2, 5, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mark Andrews"));
CALL update_lineup(2, 5, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DK Metcalf"));
CALL update_lineup(2, 5, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Cardinals D/ST"));
CALL update_lineup(2, 5, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Wil Lutz"));
CALL update_lineup(2, 6, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Drew Brees"));
CALL update_lineup(2, 6, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Nick Chubb"));
CALL update_lineup(2, 6, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Todd Gurley II"));
CALL update_lineup(2, 6, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DeAndre Hopkins"));
CALL update_lineup(2, 6, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DJ Moore"));
CALL update_lineup(2, 6, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Jared Cook"));
CALL update_lineup(2, 6, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Jonathan Taylor"));
CALL update_lineup(2, 6, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Saints D/ST"));
CALL update_lineup(2, 6, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Greg Zuerlein"));
CALL update_lineup(2, 7, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Josh Allen"));
CALL update_lineup(2, 7, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Ezekiel Elliott"));
CALL update_lineup(2, 7, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Malcolm Brown"));
CALL update_lineup(2, 7, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tyler Lockett"));
CALL update_lineup(2, 7, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DJ Chark Jr."));
CALL update_lineup(2, 7, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Hunter Henry"));
CALL update_lineup(2, 7, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Williams"));
CALL update_lineup(2, 7, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Buccaneers D/ST"));
CALL update_lineup(2, 7, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chris Boswell"));
CALL update_lineup(2, 8, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kyler Murray"));
CALL update_lineup(2, 8, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Christian McCaffrey"));
CALL update_lineup(2, 8, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Joe Mixon"));
CALL update_lineup(2, 8, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Allen Robinson II"));
CALL update_lineup(2, 8, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "JuJu Smith-Schuster"));
CALL update_lineup(2, 8, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Travis Kelce"));
CALL update_lineup(2, 8, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kareem Hunt"));
CALL update_lineup(2, 8, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chiefs D/ST"));
CALL update_lineup(2, 8, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Robbie Gould"));
CALL update_lineup(2, 9, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Dak Prescott"));
CALL update_lineup(2, 9, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Aaron Jones"));
CALL update_lineup(2, 9, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chris Carson"));
CALL update_lineup(2, 9, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "A.J. Green"));
CALL update_lineup(2, 9, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "CeeDee Lamb"));
CALL update_lineup(2, 9, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Darren Waller"));
CALL update_lineup(2, 9, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Melvin Gordon III"));
CALL update_lineup(2, 9, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "49ers D/ST"));
CALL update_lineup(2, 9, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Matt Prater"));
CALL update_lineup(2, 10, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Deshaun Watson"));
CALL update_lineup(2, 10, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Clyde Edwards-Helaire"));
CALL update_lineup(2, 10, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Miles Sanders"));
CALL update_lineup(2, 10, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Odell Beckham Jr."));
CALL update_lineup(2, 10, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Will Fuller V"));
CALL update_lineup(2, 10, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Gesicki"));
CALL update_lineup(2, 10, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "T.Y. Hilton"));
CALL update_lineup(2, 10, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Bills D/ST"));
CALL update_lineup(2, 10, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Ryan Succop"));
CALL update_lineup(3, 1, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Ben Roethlisberger"));
CALL update_lineup(3, 1, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Alvin Kamara"));
CALL update_lineup(3, 1, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Myles Gaskin"));
CALL update_lineup(3, 1, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tyreek Hill"));
CALL update_lineup(3, 1, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Evans"));
CALL update_lineup(3, 1, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Zach Ertz"));
CALL update_lineup(3, 1, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Amari Cooper"));
CALL update_lineup(3, 1, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Colts D/ST"));
CALL update_lineup(3, 1, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Zane Gonzalez"));
CALL update_lineup(3, 2, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Aaron Rodgers"));
CALL update_lineup(3, 2, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Derrick Henry"));
CALL update_lineup(3, 2, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "David Johnson"));
CALL update_lineup(3, 2, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Adam Thielen"));
CALL update_lineup(3, 2, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Julian Edelman"));
CALL update_lineup(3, 2, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Evan Engram"));
CALL update_lineup(3, 2, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Robert Woods"));
CALL update_lineup(3, 2, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Titans D/ST"));
CALL update_lineup(3, 2, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Harrison Butker"));
CALL update_lineup(3, 3, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Russell Wilson"));
CALL update_lineup(3, 3, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Josh Jacobs"));
CALL update_lineup(3, 3, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kenyan Drake"));
CALL update_lineup(3, 3, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kenny Golladay"));
CALL update_lineup(3, 3, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Cooper Kupp"));
CALL update_lineup(3, 3, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Noah Fant"));
CALL update_lineup(3, 3, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Leonard Fournette"));
CALL update_lineup(3, 3, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Giants D/ST"));
CALL update_lineup(3, 3, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mason Crosby"));
CALL update_lineup(3, 4, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Patrick Mahomes"));
CALL update_lineup(3, 4, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Dalvin Cook"));
CALL update_lineup(3, 4, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "James Conner"));
CALL update_lineup(3, 4, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Terry McLaurin"));
CALL update_lineup(3, 4, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Stefon Diggs"));
CALL update_lineup(3, 4, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tyler Higbee"));
CALL update_lineup(3, 4, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "James Robinson"));
CALL update_lineup(3, 4, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Steelers D/ST"));
CALL update_lineup(3, 4, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Justin Tucker"));
CALL update_lineup(3, 5, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Lamar Jackson"));
CALL update_lineup(3, 5, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Austin Ekeler"));
CALL update_lineup(3, 5, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Davis"));
CALL update_lineup(3, 5, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Keenan Allen"));
CALL update_lineup(3, 5, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DK Metcalf"));
CALL update_lineup(3, 5, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mark Andrews"));
CALL update_lineup(3, 5, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Calvin Ridley"));
CALL update_lineup(3, 5, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Browns D/ST"));
CALL update_lineup(3, 5, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Younghoe Koo"));
CALL update_lineup(3, 6, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Drew Brees"));
CALL update_lineup(3, 6, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Nick Chubb"));
CALL update_lineup(3, 6, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Todd Gurley II"));
CALL update_lineup(3, 6, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DeAndre Hopkins"));
CALL update_lineup(3, 6, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DJ Moore"));
CALL update_lineup(3, 6, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Jared Cook"));
CALL update_lineup(3, 6, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Jonathan Taylor"));
CALL update_lineup(3, 6, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Saints D/ST"));
CALL update_lineup(3, 6, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Greg Zuerlein"));
CALL update_lineup(3, 7, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Josh Allen"));
CALL update_lineup(3, 7, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Ezekiel Elliott"));
CALL update_lineup(3, 7, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Malcolm Brown"));
CALL update_lineup(3, 7, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chris Godwin"));
CALL update_lineup(3, 7, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tyler Lockett"));
CALL update_lineup(3, 7, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Hunter Henry"));
CALL update_lineup(3, 7, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Russell Gage"));
CALL update_lineup(3, 7, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Buccaneers D/ST"));
CALL update_lineup(3, 7, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chris Boswell"));
CALL update_lineup(3, 8, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kyler Murray"));
CALL update_lineup(3, 8, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Joe Mixon"));
CALL update_lineup(3, 8, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Kareem Hunt"));
CALL update_lineup(3, 8, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Allen Robinson II"));
CALL update_lineup(3, 8, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "JuJu Smith-Schuster"));
CALL update_lineup(3, 8, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Travis Kelce"));
CALL update_lineup(3, 8, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Robby Anderson"));
CALL update_lineup(3, 8, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Eagles D/ST"));
CALL update_lineup(3, 8, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Robbie Gould"));
CALL update_lineup(3, 9, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Dak Prescott"));
CALL update_lineup(3, 9, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Aaron Jones"));
CALL update_lineup(3, 9, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chris Carson"));
CALL update_lineup(3, 9, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "DeVante Parker"));
CALL update_lineup(3, 9, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "A.J. Green"));
CALL update_lineup(3, 9, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Darren Waller"));
CALL update_lineup(3, 9, 7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Melvin Gordon III"));
CALL update_lineup(3, 9, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "49ers D/ST"));
CALL update_lineup(3, 9, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Matt Prater"));
CALL update_lineup(3, 10, 1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Deshaun Watson"));
CALL update_lineup(3, 10, 2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Clyde Edwards-Helaire"));
CALL update_lineup(3, 10, 3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Miles Sanders"));
CALL update_lineup(3, 10, 4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Odell Beckham Jr."));
CALL update_lineup(3, 10, 5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Will Fuller V"));
CALL update_lineup(3, 10, 6, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Gesicki"));
CALL update_lineup(3, 10, 8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "T.Y. Hilton"));
CALL update_lineup(3, 10, 10, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Bills D/ST"));
CALL update_lineup(3, 10, 11, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Ryan Succop"));

INSERT INTO
	matchup (week, home_team, away_team)
VALUES
	(1, 1, 6),
	(1, 5, 7),
	(1, 3, 8),
	(1, 4, 2),
	(1, 10, 9),
	(2, 3, 1),
	(2, 7, 4),
	(2, 5, 10),
	(2, 6, 2),
	(2, 8, 9),
	(3, 2, 1),
	(3, 10, 4),
	(3, 9, 3),
	(3, 6, 7),
	(3, 8, 5),
	(4, 1, 7),
	(4, 9, 2),
	(4, 4, 5),
	(4, 10, 8),
	(4, 3, 5);

INSERT INTO
	scoring (abbreviation, statistic, points)
VALUES
	("PY", "Passing Yards", 0.04),
	("PTD", "Passing Touchdown", 4),
	("RY", "Rushing Yards", 0.1),
	("RTD", "Rushing Touchdown", 6),
	("REY", "Receiving Yards", 0.1),
	("REC", "Reception", 0.5),
	("RETD", "Receiving Touchdown", 6),
	("TO", "Turnover", -2),
	("PAT", "Point After Touchdown", 1),
	("MFG", "Missed Field Goal", -1),
	("FG", "Field Goal Made", 3),
	("DTD", "D/ST Touchdown", 6),
	("SK", "Sack", 1),
	("TOC", "Turnover Created", 2),
	("SF", "Safety", 2),
	("PA", "Points Allowed", -0.1),
	("YA", "Yards Allowed", -0.01);

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Alexander Mattison";
INSERT INTO roster VALUES (5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Derek Carr"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Tevin Coleman";
INSERT INTO roster VALUES (8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Eagles D/ST"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Le'Veon Bell";
INSERT INTO roster VALUES (7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Malcolm Brown"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Latavius Murray";
INSERT INTO roster VALUES (4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "James Robinson"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Preston Williams";
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Nyheim Hines"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Jack Doyle";
INSERT INTO roster VALUES (9, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Sammy Watkins"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Cowboys D/ST";
INSERT INTO roster VALUES (1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Dallas Goedert"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Broncos D/ST";
INSERT INTO roster VALUES (8, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Chiefs D/ST"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Ka'imi Fairbairn";
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mason Crosby"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Derek Carr";
INSERT INTO roster VALUES (5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Cardinals D/ST"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Kerryon Johnson";
INSERT INTO roster VALUES (4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Le'Veon Bell"));
COMMIT;

CALL add_player(4, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Parris Campbell"));

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Matt Breida";
INSERT INTO roster VALUES (1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Football Team D/ST"));
COMMIT;

CALL add_player(3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Scotty Miller"));

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Chris Thompson";
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Adrian Peterson"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Saquon Barkley";
INSERT INTO roster VALUES (5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Mike Davis"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Marlon Mack";
INSERT INTO roster VALUES (2, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Joshua Kelley"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Rob Gronkowski";
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Jonnu Smith"));
COMMIT;

CALL add_player(9, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Jerick McKinnon"));

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Breshad Perriman";
INSERT INTO roster VALUES (5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Younghoe Koo"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Duke Johnson";
INSERT INTO roster VALUES (5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Devonta Freeman"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) in ("Courtland Sutton", "Daniel Jones");
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Giants D/ST"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Scotty Miller";
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Gardner Minshew II"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Adrian Peterson";
INSERT INTO roster VALUES (3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Dalton Schultz"));
COMMIT;

CALL add_player(1, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Myles Gaskin"));

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Cardinals D/ST";
INSERT INTO roster VALUES (5, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Browns D/ST"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Mike Williams";
INSERT INTO roster VALUES (7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Russell Gage"));
COMMIT;

START TRANSACTION;
DELETE r FROM roster r join player p on r.player_id = p.player_id
WHERE CONCAT(p.first_name, " ", p.last_name) = "Carson Wentz";
INSERT INTO roster VALUES (7, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Justin Herbert"));
COMMIT;

CALL add_player(3, (SELECT player_id FROM player WHERE CONCAT(first_name, " ", last_name) = "Tre'Quan Smith"));

INSERT INTO
	player_performance (player_id, week, statistic, quantity)
VALUES
	(82, 1, 'PY', 312),
	(82, 1, 'PTD', 2),
	(82, 1, 'RY', 57),
	(82, 1, 'RTD', 1),
	(82, 1, 'TO', 2),
	(52, 1, 'PY', 322),
	(52, 1, 'PTD', 4),
	(52, 1, 'RY', 29),
	(52, 1, 'RTD', 0),
	(52, 1, 'TO', 1),
	(126, 1, 'PY', 364),
	(126, 1, 'PTD', 4),
	(126, 1, 'RY', 2),
	(126, 1, 'RTD', 0),
	(126, 1, 'TO', 0),
	(60, 1, 'PY', 230),
	(60, 1, 'PTD', 1),
	(60, 1, 'RY', 91),
	(60, 1, 'RTD', 1),
	(60, 1, 'TO', 1),
	(84, 1, 'PY', 450),
	(84, 1, 'PTD', 2),
	(84, 1, 'RY', -1),
	(84, 1, 'RTD', 0),
	(84, 1, 'TO', 1),
	(23, 1, 'PY', 275),
	(23, 1, 'PTD', 3),
	(23, 1, 'RY', 45),
	(23, 1, 'RTD', 0),
	(23, 1, 'TO', 1),
	(136, 1, 'PY', 155),
	(136, 1, 'PTD', 0),
	(136, 1, 'RY', 75),
	(136, 1, 'RTD', 2),
	(136, 1, 'TO', 0),
	(66, 1, 'PY', 239),
	(66, 1, 'PTD', 2),
	(66, 1, 'RY', 9),
	(66, 1, 'RTD', 1),
	(66, 1, 'TO', 3),
	(47, 1, 'PY', 253),
	(47, 1, 'PTD', 1),
	(47, 1, 'RY', 27),
	(47, 1, 'RTD', 1),
	(47, 1, 'TO', 1),
	(137, 1, 'PY', 229),
	(137, 1, 'PTD', 3),
	(137, 1, 'RY', 9),
	(137, 1, 'RTD', 0),
	(137, 1, 'TO', 1),
	(129, 1, 'PY', 279),
	(129, 1, 'PTD', 2),
	(129, 1, 'RY', 22),
	(129, 1, 'RTD', 0),
	(129, 1, 'TO', 2),
	(25, 1, 'PY', 211),
	(25, 1, 'PTD', 3),
	(25, 1, 'RY', 0),
	(25, 1, 'RTD', 0),
	(25, 1, 'TO', 0),
	(122, 1, 'PY', 270),
	(122, 1, 'PTD', 2),
	(122, 1, 'RY', 2),
	(122, 1, 'RTD', 0),
	(122, 1, 'TO', 4),
	(131, 1, 'PY', 297),
	(131, 1, 'PTD', 1),
	(131, 1, 'RY', 23),
	(131, 1, 'RTD', 0),
	(131, 1, 'TO', 1),
	(28, 1, 'PY', 266),
	(28, 1, 'PTD', 1),
	(28, 1, 'RY', 30),
	(28, 1, 'RTD', 0),
	(28, 1, 'TO', 0),
	(148, 1, 'PY', 193),
	(148, 1, 'PTD', 0),
	(148, 1, 'RY', 46),
	(148, 1, 'RTD', 1),
	(148, 1, 'TO', 2),
	(91, 1, 'PY', 160),
	(91, 1, 'PTD', 2),
	(91, 1, 'RY', 1),
	(91, 1, 'RTD', 0),
	(91, 1, 'TO', 0),
	(161, 1, 'PY', 239),
	(161, 1, 'PTD', 1),
	(161, 1, 'RY', 0),
	(161, 1, 'RTD', 0),
	(161, 1, 'TO', 0),
	(9, 1, 'RY', 93),
	(9, 1, 'RTD', 3),
	(9, 1, 'REC', 4),
	(9, 1, 'REY', 46),
	(9, 1, 'RETD', 0),
	(9, 1, 'TO', 0),
	(1, 1, 'RY', 97),
	(1, 1, 'RTD', 2),
	(1, 1, 'REC', 3),
	(1, 1, 'REY', 38),
	(1, 1, 'RETD', 0),
	(1, 1, 'TO', 0),
	(2, 1, 'RY', 96),
	(2, 1, 'RTD', 1),
	(2, 1, 'REC', 3),
	(2, 1, 'REY', 31),
	(2, 1, 'RETD', 1),
	(2, 1, 'TO', 0),
	(167, 1, 'RY', 79),
	(167, 1, 'RTD', 2),
	(167, 1, 'REC', 3),
	(167, 1, 'REY', 31),
	(167, 1, 'RETD', 0),
	(167, 1, 'TO', 0),
	(64, 1, 'RY', 56),
	(64, 1, 'RTD', 0),
	(64, 1, 'REC', 4),
	(64, 1, 'REY', 95),
	(64, 1, 'RETD', 1),
	(64, 1, 'TO', 0),
	(7, 1, 'RY', 138),
	(7, 1, 'RTD', 1),
	(7, 1, 'REC', 0),
	(7, 1, 'REY', 0),
	(7, 1, 'RETD', 0),
	(7, 1, 'TO', 0),
	(170, 1, 'RY', 28),
	(170, 1, 'RTD', 1),
	(170, 1, 'REC', 8),
	(170, 1, 'REY', 45),
	(170, 1, 'RETD', 1),
	(170, 1, 'TO', 0),
	(4, 1, 'RY', 16),
	(4, 1, 'RTD', 1),
	(4, 1, 'REC', 5),
	(4, 1, 'REY', 51),
	(4, 1, 'RETD', 1),
	(4, 1, 'TO', 0),
	(33, 1, 'RY', 21),
	(33, 1, 'RTD', 0),
	(33, 1, 'REC', 6),
	(33, 1, 'REY', 45),
	(33, 1, 'RETD', 2),
	(33, 1, 'TO', 0),
	(35, 1, 'RY', 77),
	(35, 1, 'RTD', 1),
	(35, 1, 'REC', 3),
	(35, 1, 'REY', 32),
	(35, 1, 'RETD', 0),
	(35, 1, 'TO', 0),
	(5, 1, 'RY', 50),
	(5, 1, 'RTD', 2),
	(5, 1, 'REC', 1),
	(5, 1, 'REY', -2),
	(5, 1, 'RETD', 0),
	(5, 1, 'TO', 0),
	(48, 1, 'RY', 78),
	(48, 1, 'RTD', 1),
	(48, 1, 'REC', 3),
	(48, 1, 'REY', 8),
	(48, 1, 'RETD', 0),
	(48, 1, 'TO', 1),
	(93, 1, 'RY', 22),
	(93, 1, 'RTD', 2),
	(93, 1, 'REC', 0),
	(93, 1, 'REY', 0),
	(93, 1, 'RETD', 0),
	(93, 1, 'TO', 0),
	(13, 1, 'RY', 66),
	(13, 1, 'RTD', 1),
	(13, 1, 'REC', 4),
	(13, 1, 'REY', 10),
	(13, 1, 'RETD', 0),
	(13, 1, 'TO', 1),
	(6, 1, 'RY', 116),
	(6, 1, 'RTD', 0),
	(6, 1, 'REC', 3),
	(6, 1, 'REY', 15),
	(6, 1, 'RETD', 0),
	(6, 1, 'TO', 0),
	(12, 1, 'RY', 60),
	(12, 1, 'RTD', 1),
	(12, 1, 'REC', 2),
	(12, 1, 'REY', 5),
	(12, 1, 'RETD', 0),
	(12, 1, 'TO', 0),
	(178, 1, 'RY', 60),
	(178, 1, 'RTD', 1),
	(178, 1, 'REC', 0),
	(178, 1, 'REY', 0),
	(178, 1, 'RETD', 0),
	(178, 1, 'TO', 0),
	(31, 1, 'RY', 56),
	(31, 1, 'RTD', 1),
	(31, 1, 'REC', 2),
	(31, 1, 'REY', 1),
	(31, 1, 'RETD', 0),
	(31, 1, 'TO', 0),
	(176, 1, 'RY', 93),
	(176, 1, 'RTD', 0),
	(176, 1, 'REC', 3),
	(176, 1, 'REY', 21),
	(176, 1, 'RETD', 0),
	(176, 1, 'TO', 0),
	(180, 1, 'RY', 24),
	(180, 1, 'RTD', 0),
	(180, 1, 'REC', 3),
	(180, 1, 'REY', 20),
	(180, 1, 'RETD', 1),
	(180, 1, 'TO', 0),
	(146, 1, 'RY', 37),
	(146, 1, 'RTD', 1),
	(146, 1, 'REC', 0),
	(146, 1, 'REY', 0),
	(146, 1, 'RETD', 0),
	(146, 1, 'TO', 0),
	(169, 1, 'RY', 62),
	(169, 1, 'RTD', 0),
	(169, 1, 'REC', 1),
	(169, 1, 'REY', 28),
	(169, 1, 'RETD', 0),
	(169, 1, 'TO', 0),
	(50, 1, 'RY', 22),
	(50, 1, 'RTD', 0),
	(50, 1, 'REC', 6),
	(50, 1, 'REY', 67),
	(50, 1, 'RETD', 0),
	(50, 1, 'TO', 0),
	(18, 1, 'RY', 84),
	(18, 1, 'RTD', 0),
	(18, 1, 'REC', 1),
	(18, 1, 'REY', 3),
	(18, 1, 'RETD', 0),
	(18, 1, 'TO', 0),
	(111, 1, 'RY', 11),
	(111, 1, 'RTD', 0),
	(111, 1, 'REC', 3),
	(111, 1, 'REY', 16),
	(111, 1, 'RETD', 1),
	(111, 1, 'TO', 0),
	(62, 1, 'RY', 8),
	(62, 1, 'RTD', 1),
	(62, 1, 'REC', 3),
	(62, 1, 'REY', 15),
	(62, 1, 'RETD', 0),
	(62, 1, 'TO', 0),
	(61, 1, 'RY', 72),
	(61, 1, 'RTD', 0),
	(61, 1, 'REC', 4),
	(61, 1, 'REY', 9),
	(61, 1, 'RETD', 0),
	(61, 1, 'TO', 1),
	(143, 1, 'RY', 50),
	(143, 1, 'RTD', 0),
	(143, 1, 'REC', 4),
	(143, 1, 'REY', 30),
	(143, 1, 'RETD', 0),
	(143, 1, 'TO', 0),
	(75, 1, 'RY', 64),
	(75, 1, 'RTD', 0),
	(75, 1, 'REC', 1),
	(75, 1, 'REY', 10),
	(75, 1, 'RETD', 0),
	(75, 1, 'TO', 0),
	(20, 1, 'RY', 69),
	(20, 1, 'RTD', 0),
	(20, 1, 'REC', 1),
	(20, 1, 'REY', 2),
	(20, 1, 'RETD', 0),
	(20, 1, 'TO', 1),
	(87, 1, 'RY', 7),
	(87, 1, 'RTD', 1),
	(87, 1, 'REC', 0),
	(87, 1, 'REY', 0),
	(87, 1, 'RETD', 0),
	(87, 1, 'TO', 0),
	(3, 1, 'RY', 6),
	(3, 1, 'RTD', 0),
	(3, 1, 'REC', 6),
	(3, 1, 'REY', 60),
	(3, 1, 'RETD', 0),
	(3, 1, 'TO', 0),
	(10, 1, 'RY', 60),
	(10, 1, 'RTD', 0),
	(10, 1, 'REC', 1),
	(10, 1, 'REY', 6),
	(10, 1, 'RETD', 0),
	(10, 1, 'TO', 1),
	(168, 1, 'RY', 40),
	(168, 1, 'RTD', 0),
	(168, 1, 'REC', 4),
	(168, 1, 'REY', 26),
	(168, 1, 'RETD', 0),
	(168, 1, 'TO', 0),
	(135, 1, 'RY', 26),
	(135, 1, 'RTD', 0),
	(135, 1, 'REC', 3),
	(135, 1, 'REY', 30),
	(135, 1, 'RETD', 0),
	(135, 1, 'TO', 0),
	(56, 1, 'RY', 30),
	(56, 1, 'RTD', 0),
	(56, 1, 'REC', 5),
	(56, 1, 'REY', 23),
	(56, 1, 'RETD', 0),
	(56, 1, 'TO', 0),
	(70, 1, 'RY', 22),
	(70, 1, 'RTD', 0),
	(70, 1, 'REC', 3),
	(70, 1, 'REY', 30),
	(70, 1, 'RETD', 0),
	(70, 1, 'TO', 0),
	(145, 1, 'RY', 48),
	(145, 1, 'RTD', 0),
	(145, 1, 'REC', 0),
	(145, 1, 'REY', 0),
	(145, 1, 'RETD', 0),
	(145, 1, 'TO', 0),
	(83, 1, 'RY', 41),
	(83, 1, 'RTD', 0),
	(83, 1, 'REC', 2),
	(83, 1, 'REY', 6),
	(83, 1, 'RETD', 0),
	(83, 1, 'TO', 0),
	(39, 1, 'RY', 14),
	(39, 1, 'RTD', 0),
	(39, 1, 'REC', 2),
	(39, 1, 'REY', 32),
	(39, 1, 'RETD', 0),
	(39, 1, 'TO', 0),
	(74, 1, 'RY', 36),
	(74, 1, 'RTD', 0),
	(74, 1, 'REC', 2),
	(74, 1, 'REY', 8),
	(74, 1, 'RETD', 0),
	(74, 1, 'TO', 0),
	(57, 1, 'RY', 39),
	(57, 1, 'RTD', 0),
	(57, 1, 'REC', 1),
	(57, 1, 'REY', 4),
	(57, 1, 'RETD', 0),
	(57, 1, 'TO', 0),
	(101, 1, 'RY', 24),
	(101, 1, 'RTD', 0),
	(101, 1, 'REC', 1),
	(101, 1, 'REY', 11),
	(101, 1, 'RETD', 0),
	(101, 1, 'TO', 0),
	(134, 1, 'RY', 23),
	(134, 1, 'RTD', 0),
	(134, 1, 'REC', 2),
	(134, 1, 'REY', 7),
	(134, 1, 'RETD', 0),
	(134, 1, 'TO', 0),
	(140, 1, 'RY', 18),
	(140, 1, 'RTD', 0),
	(140, 1, 'REC', 1),
	(140, 1, 'REY', 6),
	(140, 1, 'RETD', 0),
	(140, 1, 'TO', 0),
	(104, 1, 'RY', 22),
	(104, 1, 'RTD', 0),
	(104, 1, 'REC', 0),
	(104, 1, 'REY', 0),
	(104, 1, 'RETD', 0),
	(104, 1, 'TO', 0),
	(69, 1, 'RY', 5),
	(69, 1, 'RTD', 0),
	(69, 1, 'REC', 1),
	(69, 1, 'REY', 14),
	(69, 1, 'RETD', 0),
	(69, 1, 'TO', 0),
	(36, 1, 'RY', 9),
	(36, 1, 'RTD', 0),
	(36, 1, 'REC', 2),
	(36, 1, 'REY', 8),
	(36, 1, 'RETD', 0),
	(36, 1, 'TO', 0),
	(138, 1, 'RY', 14),
	(138, 1, 'RTD', 0),
	(138, 1, 'REC', 0),
	(138, 1, 'REY', 0),
	(138, 1, 'RETD', 0),
	(138, 1, 'TO', 0),
	(85, 1, 'RY', 14),
	(85, 1, 'RTD', 0),
	(85, 1, 'REC', 0),
	(85, 1, 'REY', 0),
	(85, 1, 'RETD', 0),
	(85, 1, 'TO', 0),
	(149, 1, 'RY', 0),
	(149, 1, 'RTD', 0),
	(149, 1, 'REC', 2),
	(149, 1, 'REY', 6),
	(149, 1, 'RETD', 0),
	(149, 1, 'TO', 0),
	(15, 1, 'RY', 0),
	(15, 1, 'RTD', 0),
	(15, 1, 'REC', 14),
	(15, 1, 'REY', 156),
	(15, 1, 'RETD', 2),
	(15, 1, 'TO', 0),
	(43, 1, 'RY', -1),
	(43, 1, 'RTD', 0),
	(43, 1, 'REC', 9),
	(43, 1, 'REY', 130),
	(43, 1, 'RETD', 2),
	(43, 1, 'TO', 0),
	(26, 1, 'RY', 0),
	(26, 1, 'RTD', 0),
	(26, 1, 'REC', 6),
	(26, 1, 'REY', 110),
	(26, 1, 'RETD', 2),
	(26, 1, 'TO', 0),
	(120, 1, 'RY', 0),
	(120, 1, 'RTD', 0),
	(120, 1, 'REC', 6),
	(120, 1, 'REY', 102),
	(120, 1, 'RETD', 2),
	(120, 1, 'TO', 0),
	(41, 1, 'RY', 0),
	(41, 1, 'RTD', 0),
	(41, 1, 'REC', 6),
	(41, 1, 'REY', 69),
	(41, 1, 'RETD', 2),
	(41, 1, 'TO', 0),
	(99, 1, 'RY', 0),
	(99, 1, 'RTD', 0),
	(99, 1, 'REC', 7),
	(99, 1, 'REY', 115),
	(99, 1, 'RETD', 1),
	(99, 1, 'TO', 0),
	(121, 1, 'RY', 0),
	(121, 1, 'RTD', 0),
	(121, 1, 'REC', 6),
	(121, 1, 'REY', 114),
	(121, 1, 'RETD', 1),
	(121, 1, 'TO', 0),
	(16, 1, 'RY', 0),
	(16, 1, 'RTD', 0),
	(16, 1, 'REC', 9),
	(16, 1, 'REY', 157),
	(16, 1, 'RETD', 0),
	(16, 1, 'TO', 0),
	(63, 1, 'RY', 0),
	(63, 1, 'RTD', 0),
	(63, 1, 'REC', 4),
	(63, 1, 'REY', 95),
	(63, 1, 'RETD', 1),
	(63, 1, 'TO', 0),
	(11, 1, 'RY', 0),
	(11, 1, 'RTD', 0),
	(11, 1, 'REC', 14),
	(11, 1, 'REY', 151),
	(11, 1, 'RETD', 0),
	(11, 1, 'TO', 0),
	(171, 1, 'RY', 3),
	(171, 1, 'RTD', 0),
	(171, 1, 'REC', 7),
	(171, 1, 'REY', 82),
	(171, 1, 'RETD', 1),
	(171, 1, 'TO', 0),
	(123, 1, 'RY', 0),
	(123, 1, 'RTD', 0),
	(123, 1, 'REC', 6),
	(123, 1, 'REY', 70),
	(123, 1, 'RETD', 1),
	(123, 1, 'TO', 0),
	(46, 1, 'RY', 14),
	(46, 1, 'RTD', 0),
	(46, 1, 'REC', 6),
	(46, 1, 'REY', 105),
	(46, 1, 'RETD', 0),
	(46, 1, 'TO', 0),
	(187, 1, 'RY', 0),
	(187, 1, 'RTD', 0),
	(187, 1, 'REC', 9),
	(187, 1, 'REY', 114),
	(187, 1, 'RETD', 0),
	(187, 1, 'TO', 0),
	(67, 1, 'RY', 0),
	(67, 1, 'RTD', 0),
	(67, 1, 'REC', 8),
	(67, 1, 'REY', 112),
	(67, 1, 'RETD', 0),
	(67, 1, 'TO', 0),
	(17, 1, 'RY', 0),
	(17, 1, 'RTD', 0),
	(17, 1, 'REC', 5),
	(17, 1, 'REY', 46),
	(17, 1, 'RETD', 1),
	(17, 1, 'TO', 0),
	(72, 1, 'RY', 0),
	(72, 1, 'RTD', 0),
	(72, 1, 'REC', 5),
	(72, 1, 'REY', 101),
	(72, 1, 'RETD', 0),
	(72, 1, 'TO', 0),
	(42, 1, 'RY', 0),
	(42, 1, 'RTD', 0),
	(42, 1, 'REC', 8),
	(42, 1, 'REY', 92),
	(42, 1, 'RETD', 0),
	(42, 1, 'TO', 0),
	(76, 1, 'RY', 0),
	(76, 1, 'RTD', 0),
	(76, 1, 'REC', 8),
	(76, 1, 'REY', 86),
	(76, 1, 'RETD', 0),
	(76, 1, 'TO', 0),
	(59, 1, 'RY', 0),
	(59, 1, 'RTD', 0),
	(59, 1, 'REC', 3),
	(59, 1, 'REY', 25),
	(59, 1, 'RETD', 1),
	(59, 1, 'TO', 0),
	(37, 1, 'RY', 0),
	(37, 1, 'RTD', 0),
	(37, 1, 'REC', 10),
	(37, 1, 'REY', 81),
	(37, 1, 'RETD', 0),
	(37, 1, 'TO', 0),
	(86, 1, 'RY', 23),
	(86, 1, 'RTD', 0),
	(86, 1, 'REC', 5),
	(86, 1, 'REY', 57),
	(86, 1, 'RETD', 0),
	(86, 1, 'TO', 0),
	(173, 1, 'RY', 9),
	(173, 1, 'RTD', 0),
	(173, 1, 'REC', 6),
	(173, 1, 'REY', 71),
	(173, 1, 'RETD', 0),
	(173, 1, 'TO', 0),
	(19, 1, 'RY', 0),
	(19, 1, 'RTD', 0),
	(19, 1, 'REC', 6),
	(19, 1, 'REY', 79),
	(19, 1, 'RETD', 0),
	(19, 1, 'TO', 0),
	(175, 1, 'RY', 6),
	(175, 1, 'RTD', 0),
	(175, 1, 'REC', 5),
	(175, 1, 'REY', 73),
	(175, 1, 'RETD', 0),
	(175, 1, 'TO', 0),
	(117, 1, 'RY', 0),
	(117, 1, 'RTD', 0),
	(117, 1, 'REC', 3),
	(117, 1, 'REY', 15),
	(117, 1, 'RETD', 1),
	(117, 1, 'TO', 0),
	(40, 1, 'RY', -1),
	(40, 1, 'RTD', 0),
	(40, 1, 'REC', 5),
	(40, 1, 'REY', 74),
	(40, 1, 'RETD', 0),
	(40, 1, 'TO', 0),
	(139, 1, 'RY', 0),
	(139, 1, 'RTD', 0),
	(139, 1, 'REC', 4),
	(139, 1, 'REY', 69),
	(139, 1, 'RETD', 0),
	(139, 1, 'TO', 0),
	(89, 1, 'RY', 11),
	(89, 1, 'RTD', 0),
	(89, 1, 'REC', 3),
	(89, 1, 'REY', 55),
	(89, 1, 'RETD', 0),
	(89, 1, 'TO', 0),
	(24, 1, 'RY', 0),
	(24, 1, 'RTD', 0),
	(24, 1, 'REC', 1),
	(24, 1, 'REY', 2),
	(24, 1, 'RETD', 1),
	(24, 1, 'TO', 0),
	(51, 1, 'RY', 0),
	(51, 1, 'RTD', 0),
	(51, 1, 'REC', 5),
	(51, 1, 'REY', 61),
	(51, 1, 'RETD', 0),
	(51, 1, 'TO', 0),
	(45, 1, 'RY', 0),
	(45, 1, 'RTD', 0),
	(45, 1, 'REC', 5),
	(45, 1, 'REY', 61),
	(45, 1, 'RETD', 0),
	(45, 1, 'TO', 0),
	(113, 1, 'RY', 0),
	(113, 1, 'RTD', 0),
	(113, 1, 'REC', 5),
	(113, 1, 'REY', 59),
	(113, 1, 'RETD', 0),
	(113, 1, 'TO', 0),
	(100, 1, 'RY', 0),
	(100, 1, 'RTD', 0),
	(100, 1, 'REC', 6),
	(100, 1, 'REY', 57),
	(100, 1, 'RETD', 0),
	(100, 1, 'TO', 1),
	(105, 1, 'RY', 0),
	(105, 1, 'RTD', 0),
	(105, 1, 'REC', 4),
	(105, 1, 'REY', 56),
	(105, 1, 'RETD', 0),
	(105, 1, 'TO', 1),
	(30, 1, 'RY', 0),
	(30, 1, 'RTD', 0),
	(30, 1, 'REC', 4),
	(30, 1, 'REY', 54),
	(30, 1, 'RETD', 0),
	(30, 1, 'TO', 0),
	(54, 1, 'RY', 0),
	(54, 1, 'RTD', 0),
	(54, 1, 'REC', 4),
	(54, 1, 'REY', 53),
	(54, 1, 'RETD', 0),
	(54, 1, 'TO', 0),
	(73, 1, 'RY', 0),
	(73, 1, 'RTD', 0),
	(73, 1, 'REC', 5),
	(73, 1, 'REY', 51),
	(73, 1, 'RETD', 0),
	(73, 1, 'TO', 0),
	(80, 1, 'RY', 0),
	(80, 1, 'RTD', 0),
	(80, 1, 'REC', 3),
	(80, 1, 'REY', 50),
	(80, 1, 'RETD', 0),
	(80, 1, 'TO', 0),
	(68, 1, 'RY', 0),
	(68, 1, 'RTD', 0),
	(68, 1, 'REC', 4),
	(68, 1, 'REY', 47),
	(68, 1, 'RETD', 0),
	(68, 1, 'TO', 0),
	(77, 1, 'RY', 0),
	(77, 1, 'RTD', 0),
	(77, 1, 'REC', 6),
	(77, 1, 'REY', 47),
	(77, 1, 'RETD', 0),
	(77, 1, 'TO', 0),
	(94, 1, 'RY', 0),
	(94, 1, 'RTD', 0),
	(94, 1, 'REC', 2),
	(94, 1, 'REY', 46),
	(94, 1, 'RETD', 0),
	(94, 1, 'TO', 0),
	(112, 1, 'RY', 0),
	(112, 1, 'RTD', 0),
	(112, 1, 'REC', 2),
	(112, 1, 'REY', 41),
	(112, 1, 'RETD', 0),
	(112, 1, 'TO', 0),
	(49, 1, 'RY', 0),
	(49, 1, 'RTD', 0),
	(49, 1, 'REC', 4),
	(49, 1, 'REY', 40),
	(49, 1, 'RETD', 0),
	(49, 1, 'TO', 0),
	(34, 1, 'RY', 0),
	(34, 1, 'RTD', 0),
	(34, 1, 'REC', 5),
	(34, 1, 'REY', 39),
	(34, 1, 'RETD', 0),
	(34, 1, 'TO', 0),
	(147, 1, 'RY', 0),
	(147, 1, 'RTD', 0),
	(147, 1, 'REC', 5),
	(147, 1, 'REY', 39),
	(147, 1, 'RETD', 0),
	(147, 1, 'TO', 1),
	(58, 1, 'RY', 0),
	(58, 1, 'RTD', 0),
	(58, 1, 'REC', 4),
	(58, 1, 'REY', 37),
	(58, 1, 'RETD', 0),
	(58, 1, 'TO', 0),
	(78, 1, 'RY', 0),
	(78, 1, 'RTD', 0),
	(78, 1, 'REC', 4),
	(78, 1, 'REY', 33),
	(78, 1, 'RETD', 0),
	(78, 1, 'TO', 0),
	(154, 1, 'RY', 0),
	(154, 1, 'RTD', 0),
	(154, 1, 'REC', 2),
	(154, 1, 'REY', 26),
	(154, 1, 'RETD', 0),
	(154, 1, 'TO', 0),
	(27, 1, 'RY', 0),
	(27, 1, 'RTD', 0),
	(27, 1, 'REC', 3),
	(27, 1, 'REY', 22),
	(27, 1, 'RETD', 0),
	(27, 1, 'TO', 0),
	(88, 1, 'RY', 0),
	(88, 1, 'RTD', 0),
	(88, 1, 'REC', 2),
	(88, 1, 'REY', 20),
	(88, 1, 'RETD', 0),
	(88, 1, 'TO', 0),
	(158, 1, 'RY', 0),
	(158, 1, 'RTD', 0),
	(158, 1, 'REC', 3),
	(158, 1, 'REY', 17),
	(158, 1, 'RETD', 0),
	(158, 1, 'TO', 0),
	(8, 1, 'RY', 0),
	(8, 1, 'RTD', 0),
	(8, 1, 'REC', 3),
	(8, 1, 'REY', 17),
	(8, 1, 'RETD', 0),
	(8, 1, 'TO', 0),
	(38, 1, 'RY', 0),
	(38, 1, 'RTD', 0),
	(38, 1, 'REC', 5),
	(38, 1, 'REY', 58),
	(38, 1, 'RETD', 2),
	(38, 1, 'TO', 0),
	(172, 1, 'RY', 0),
	(172, 1, 'RTD', 0),
	(172, 1, 'REC', 8),
	(172, 1, 'REY', 101),
	(172, 1, 'RETD', 1),
	(172, 1, 'TO', 0),
	(109, 1, 'RY', 0),
	(109, 1, 'RTD', 0),
	(109, 1, 'REC', 5),
	(109, 1, 'REY', 81),
	(109, 1, 'RETD', 1),
	(109, 1, 'TO', 0),
	(116, 1, 'RY', 0),
	(116, 1, 'RTD', 0),
	(116, 1, 'REC', 5),
	(116, 1, 'REY', 56),
	(116, 1, 'RETD', 1),
	(116, 1, 'TO', 0),
	(21, 1, 'RY', 0),
	(21, 1, 'RTD', 0),
	(21, 1, 'REC', 6),
	(21, 1, 'REY', 50),
	(21, 1, 'RETD', 1),
	(21, 1, 'TO', 0),
	(179, 1, 'RY', 0),
	(179, 1, 'RTD', 0),
	(179, 1, 'REC', 4),
	(179, 1, 'REY', 36),
	(179, 1, 'RETD', 1),
	(179, 1, 'TO', 0),
	(71, 1, 'RY', 0),
	(71, 1, 'RTD', 0),
	(71, 1, 'REC', 5),
	(71, 1, 'REY', 80),
	(71, 1, 'RETD', 0),
	(71, 1, 'TO', 0),
	(44, 1, 'RY', 0),
	(44, 1, 'RTD', 0),
	(44, 1, 'REC', 3),
	(44, 1, 'REY', 18),
	(44, 1, 'RETD', 1),
	(44, 1, 'TO', 0),
	(102, 1, 'RY', 0),
	(102, 1, 'RTD', 0),
	(102, 1, 'REC', 5),
	(102, 1, 'REY', 73),
	(102, 1, 'RETD', 0),
	(102, 1, 'TO', 0),
	(22, 1, 'RY', 9),
	(22, 1, 'RTD', 0),
	(22, 1, 'REC', 4),
	(22, 1, 'REY', 44),
	(22, 1, 'RETD', 0),
	(22, 1, 'TO', 0),
	(153, 1, 'RY', 0),
	(153, 1, 'RTD', 0),
	(153, 1, 'REC', 3),
	(153, 1, 'REY', 49),
	(153, 1, 'RETD', 0),
	(153, 1, 'TO', 0),
	(53, 1, 'RY', 0),
	(53, 1, 'RTD', 0),
	(53, 1, 'REC', 6),
	(53, 1, 'REY', 45),
	(53, 1, 'RETD', 0),
	(53, 1, 'TO', 0),
	(65, 1, 'RY', 0),
	(65, 1, 'RTD', 0),
	(65, 1, 'REC', 3),
	(65, 1, 'REY', 40),
	(65, 1, 'RETD', 0),
	(65, 1, 'TO', 0),
	(133, 1, 'RY', 0),
	(133, 1, 'RTD', 0),
	(133, 1, 'REC', 3),
	(133, 1, 'REY', 38),
	(133, 1, 'RETD', 0),
	(133, 1, 'TO', 0),
	(114, 1, 'RY', 0),
	(114, 1, 'RTD', 0),
	(114, 1, 'REC', 3),
	(114, 1, 'REY', 30),
	(114, 1, 'RETD', 0),
	(114, 1, 'TO', 0),
	(92, 1, 'RY', 0),
	(92, 1, 'RTD', 0),
	(92, 1, 'REC', 2),
	(92, 1, 'REY', 11),
	(92, 1, 'RETD', 0),
	(92, 1, 'TO', 0),
	(185, 1, 'RY', 0),
	(185, 1, 'RTD', 0),
	(185, 1, 'REC', 1),
	(185, 1, 'REY', 11),
	(185, 1, 'RETD', 0),
	(185, 1, 'TO', 0),
	(55, 1, 'RY', 0),
	(55, 1, 'RTD', 0),
	(55, 1, 'REC', 2),
	(55, 1, 'REY', 9),
	(55, 1, 'RETD', 0),
	(55, 1, 'TO', 0),
	(130, 1, 'SK', 3),
	(130, 1, 'TOC', 3),
	(130, 1, 'DTD', 1),
	(130, 1, 'SF', 0),
	(130, 1, 'YA', 310),
	(130, 1, 'PA', 23),
	(106, 1, 'SK', 2),
	(106, 1, 'TOC', 3),
	(106, 1, 'DTD', 0),
	(106, 1, 'SF', 0),
	(106, 1, 'YA', 306),
	(106, 1, 'PA', 6),
	(103, 1, 'SK', 1),
	(103, 1, 'TOC', 3),
	(103, 1, 'DTD', 0),
	(103, 1, 'SF', 0),
	(103, 1, 'YA', 269),
	(103, 1, 'PA', 11),
	(96, 1, 'SK', 3),
	(96, 1, 'TOC', 2),
	(96, 1, 'DTD', 0),
	(96, 1, 'SF', 0),
	(96, 1, 'YA', 291),
	(96, 1, 'PA', 16),
	(107, 1, 'SK', 3),
	(107, 1, 'TOC', 2),
	(107, 1, 'DTD', 0),
	(107, 1, 'SF', 0),
	(107, 1, 'YA', 254),
	(107, 1, 'PA', 17),
	(156, 1, 'SK', 2),
	(156, 1, 'TOC', 2),
	(156, 1, 'DTD', 0),
	(156, 1, 'SF', 0),
	(156, 1, 'YA', 506),
	(156, 1, 'PA', 25),
	(165, 1, 'SK', 4),
	(165, 1, 'TOC', 1),
	(165, 1, 'DTD', 0),
	(165, 1, 'SF', 0),
	(165, 1, 'YA', 360),
	(165, 1, 'PA', 20),
	(183, 1, 'SK', 2),
	(183, 1, 'TOC', 1),
	(183, 1, 'DTD', 0),
	(183, 1, 'SF', 0),
	(183, 1, 'YA', 349),
	(183, 1, 'PA', 26),
	(124, 1, 'SK', 4),
	(124, 1, 'TOC', 0),
	(124, 1, 'DTD', 0),
	(124, 1, 'SF', 0),
	(124, 1, 'YA', 241),
	(124, 1, 'PA', 27),
	(186, 1, 'SK', 2),
	(186, 1, 'TOC', 1),
	(186, 1, 'DTD', 0),
	(186, 1, 'SF', 0),
	(186, 1, 'YA', 377),
	(186, 1, 'PA', 38),
	(108, 1, 'SK', 2),
	(108, 1, 'TOC', 1),
	(108, 1, 'DTD', 0),
	(108, 1, 'SF', 0),
	(108, 1, 'YA', 404),
	(108, 1, 'PA', 24),
	(144, 1, 'SK', 1),
	(144, 1, 'TOC', 1),
	(144, 1, 'DTD', 0),
	(144, 1, 'SF', 0),
	(144, 1, 'YA', 422),
	(144, 1, 'PA', 20),
	(164, 1, 'SK', 3),
	(164, 1, 'TOC', 0),
	(164, 1, 'DTD', 0),
	(164, 1, 'SF', 0),
	(164, 1, 'YA', 366),
	(164, 1, 'PA', 20),
	(132, 1, 'SK', 1),
	(132, 1, 'TOC', 1),
	(132, 1, 'DTD', 0),
	(132, 1, 'SF', 0),
	(132, 1, 'YA', 426),
	(132, 1, 'PA', 23),
	(162, 1, 'SK', 3),
	(162, 1, 'TOC', 0),
	(162, 1, 'DTD', 0),
	(162, 1, 'SF', 0),
	(162, 1, 'YA', 239),
	(162, 1, 'PA', 27),
	(119, 1, 'SK', 0),
	(119, 1, 'TOC', 1),
	(119, 1, 'DTD', 0),
	(119, 1, 'SF', 0),
	(119, 1, 'YA', 522),
	(119, 1, 'PA', 43),
	(155, 1, 'SK', 0),
	(155, 1, 'TOC', 1),
	(155, 1, 'DTD', 0),
	(155, 1, 'SF', 0),
	(155, 1, 'YA', 323),
	(155, 1, 'PA', 14),
	(141, 1, 'SK', 1),
	(141, 1, 'TOC', 0),
	(141, 1, 'DTD', 0),
	(141, 1, 'SF', 0),
	(141, 1, 'YA', 377),
	(141, 1, 'PA', 16),
	(142, 1, 'SK', 1),
	(142, 1, 'TOC', 0),
	(142, 1, 'DTD', 0),
	(142, 1, 'SF', 0),
	(142, 1, 'YA', 271),
	(142, 1, 'PA', 34),
	(166, 1, 'MFG', 0),
	(166, 1, 'FG', 2),
	(166, 1, 'PAT', 5),
	(128, 1, 'MFG', 1),
	(128, 1, 'FG', 3),
	(128, 1, 'PAT', 2),
	(98, 1, 'MFG', 0),
	(98, 1, 'FG', 2),
	(98, 1, 'PAT', 4),
	(95, 1, 'MFG', 0),
	(95, 1, 'FG', 2),
	(95, 1, 'PAT', 4),
	(160, 1, 'MFG', 0),
	(160, 1, 'FG', 2),
	(160, 1, 'PAT', 2),
	(125, 1, 'MFG', 0),
	(125, 1, 'FG', 1),
	(125, 1, 'PAT', 5),
	(159, 1, 'MFG', 0),
	(159, 1, 'FG', 2),
	(159, 1, 'PAT', 2),
	(181, 1, 'MFG', 0),
	(181, 1, 'FG', 2),
	(181, 1, 'PAT', 1),
	(157, 1, 'MFG', 2),
	(157, 1, 'FG', 1),
	(157, 1, 'PAT', 3),
	(127, 1, 'MFG', 1),
	(127, 1, 'FG', 1),
	(127, 1, 'PAT', 2),
	(150, 1, 'MFG', 1),
	(150, 1, 'FG', 1),
	(150, 1, 'PAT', 2),
	(152, 1, 'MFG', 1),
	(152, 1, 'FG', 0),
	(152, 1, 'PAT', 2),
	(28, 2, 'PY', 450),
	(28, 2, 'PTD', 1),
	(28, 2, 'RY', 18),
	(28, 2, 'RTD', 3),
	(28, 2, 'TO', 1),
	(136, 2, 'PY', 397),
	(136, 2, 'PTD', 1),
	(136, 2, 'RY', 47),
	(136, 2, 'RTD', 2),
	(136, 2, 'TO', 1),
	(82, 2, 'PY', 415),
	(82, 2, 'PTD', 4),
	(82, 2, 'RY', 19),
	(82, 2, 'RTD', 0),
	(82, 2, 'TO', 0),
	(52, 2, 'PY', 288),
	(52, 2, 'PTD', 5),
	(52, 2, 'RY', 39),
	(52, 2, 'RTD', 0),
	(52, 2, 'TO', 1),
	(60, 2, 'PY', 286),
	(60, 2, 'PTD', 1),
	(60, 2, 'RY', 67),
	(60, 2, 'RTD', 2),
	(60, 2, 'TO', 1),
	(84, 2, 'PY', 273),
	(84, 2, 'PTD', 4),
	(84, 2, 'RY', 16),
	(84, 2, 'RTD', 0),
	(84, 2, 'TO', 0),
	(148, 2, 'PY', 316),
	(148, 2, 'PTD', 3),
	(148, 2, 'RY', 19),
	(148, 2, 'RTD', 0),
	(148, 2, 'TO', 2),
	(25, 2, 'PY', 302),
	(25, 2, 'PTD', 2),
	(25, 2, 'RY', 54),
	(25, 2, 'RTD', 0),
	(25, 2, 'TO', 0),
	(188, 2, 'PY', 311),
	(188, 2, 'PTD', 1),
	(188, 2, 'RY', 18),
	(188, 2, 'RTD', 1),
	(188, 2, 'TO', 1),
	(161, 2, 'PY', 284),
	(161, 2, 'PTD', 3),
	(161, 2, 'RY', 3),
	(161, 2, 'RTD', 0),
	(161, 2, 'TO', 2),
	(137, 2, 'PY', 311),
	(137, 2, 'PTD', 2),
	(137, 2, 'RY', -2),
	(137, 2, 'RTD', 0),
	(137, 2, 'TO', 2),
	(126, 2, 'PY', 240),
	(126, 2, 'PTD', 2),
	(126, 2, 'RY', 12),
	(126, 2, 'RTD', 0),
	(126, 2, 'TO', 0),
	(131, 2, 'PY', 244),
	(131, 2, 'PTD', 2),
	(131, 2, 'RY', 4),
	(131, 2, 'RTD', 0),
	(131, 2, 'TO', 1),
	(91, 2, 'PY', 312),
	(91, 2, 'PTD', 1),
	(91, 2, 'RY', 0),
	(91, 2, 'RTD', 0),
	(91, 2, 'TO', 1),
	(23, 2, 'PY', 204),
	(23, 2, 'PTD', 1),
	(23, 2, 'RY', 54),
	(23, 2, 'RTD', 0),
	(23, 2, 'TO', 0),
	(47, 2, 'PY', 275),
	(47, 2, 'PTD', 1),
	(47, 2, 'RY', 17),
	(47, 2, 'RTD', 0),
	(47, 2, 'TO', 1),
	(122, 2, 'PY', 242),
	(122, 2, 'PTD', 0),
	(122, 2, 'RY', 7),
	(122, 2, 'RTD', 1),
	(122, 2, 'TO', 2),
	(66, 2, 'PY', 217),
	(66, 2, 'PTD', 1),
	(66, 2, 'RY', 0),
	(66, 2, 'RTD', 0),
	(66, 2, 'TO', 2),
	(129, 2, 'PY', 241),
	(129, 2, 'PTD', 0),
	(129, 2, 'RY', 21),
	(129, 2, 'RTD', 0),
	(129, 2, 'TO', 2),
	(13, 2, 'RY', 168),
	(13, 2, 'RTD', 2),
	(13, 2, 'REC', 4),
	(13, 2, 'REY', 68),
	(13, 2, 'RETD', 1),
	(13, 2, 'TO', 0),
	(4, 2, 'RY', 79),
	(4, 2, 'RTD', 2),
	(4, 2, 'REC', 9),
	(4, 2, 'REY', 95),
	(4, 2, 'RETD', 0),
	(4, 2, 'TO', 0),
	(10, 2, 'RY', 124),
	(10, 2, 'RTD', 2),
	(10, 2, 'REC', 1),
	(10, 2, 'REY', 9),
	(10, 2, 'RETD', 0),
	(10, 2, 'TO', 0),
	(69, 2, 'RY', 103),
	(69, 2, 'RTD', 2),
	(69, 2, 'REC', 4),
	(69, 2, 'REY', 13),
	(69, 2, 'RETD', 0),
	(69, 2, 'TO', 0),
	(61, 2, 'RY', 86),
	(61, 2, 'RTD', 1),
	(61, 2, 'REC', 2),
	(61, 2, 'REY', 15),
	(61, 2, 'RETD', 1),
	(61, 2, 'TO', 0),
	(1, 2, 'RY', 59),
	(1, 2, 'RTD', 2),
	(1, 2, 'REC', 4),
	(1, 2, 'REY', 29),
	(1, 2, 'RETD', 0),
	(1, 2, 'TO', 0),
	(14, 2, 'RY', 95),
	(14, 2, 'RTD', 1),
	(14, 2, 'REC', 3),
	(14, 2, 'REY', 36),
	(14, 2, 'RETD', 0),
	(14, 2, 'TO', 1),
	(75, 2, 'RY', 82),
	(75, 2, 'RTD', 0),
	(75, 2, 'REC', 3),
	(75, 2, 'REY', 45),
	(75, 2, 'RETD', 1),
	(75, 2, 'TO', 0),
	(2, 2, 'RY', 89),
	(2, 2, 'RTD', 1),
	(2, 2, 'REC', 6),
	(2, 2, 'REY', 33),
	(2, 2, 'RETD', 0),
	(2, 2, 'TO', 2),
	(36, 2, 'RY', 106),
	(36, 2, 'RTD', 1),
	(36, 2, 'REC', 2),
	(36, 2, 'REY', 15),
	(36, 2, 'RETD', 0),
	(36, 2, 'TO', 0),
	(169, 2, 'RY', 102),
	(169, 2, 'RTD', 1),
	(169, 2, 'REC', 3),
	(169, 2, 'REY', 18),
	(169, 2, 'RETD', 0),
	(169, 2, 'TO', 0),
	(50, 2, 'RY', 101),
	(50, 2, 'RTD', 1),
	(50, 2, 'REC', 2),
	(50, 2, 'REY', 9),
	(50, 2, 'RETD', 0),
	(50, 2, 'TO', 0),
	(33, 2, 'RY', 72),
	(33, 2, 'RTD', 0),
	(33, 2, 'REC', 3),
	(33, 2, 'REY', 36),
	(33, 2, 'RETD', 1),
	(33, 2, 'TO', 0),
	(64, 2, 'RY', 92),
	(64, 2, 'RTD', 1),
	(64, 2, 'REC', 2),
	(64, 2, 'REY', 15),
	(64, 2, 'RETD', 0),
	(64, 2, 'TO', 0),
	(18, 2, 'RY', 93),
	(18, 2, 'RTD', 0),
	(18, 2, 'REC', 4),
	(18, 2, 'REY', 55),
	(18, 2, 'RETD', 0),
	(18, 2, 'TO', 0),
	(20, 2, 'RY', 46),
	(20, 2, 'RTD', 0),
	(20, 2, 'REC', 4),
	(20, 2, 'REY', 40),
	(20, 2, 'RETD', 1),
	(20, 2, 'TO', 0),
	(48, 2, 'RY', 70),
	(48, 2, 'RTD', 0),
	(48, 2, 'REC', 2),
	(48, 2, 'REY', 14),
	(48, 2, 'RETD', 1),
	(48, 2, 'TO', 0),
	(180, 2, 'RY', 77),
	(180, 2, 'RTD', 1),
	(180, 2, 'REC', 0),
	(180, 2, 'REY', 0),
	(180, 2, 'RETD', 0),
	(180, 2, 'TO', 0),
	(5, 2, 'RY', 63),
	(5, 2, 'RTD', 1),
	(5, 2, 'REC', 2),
	(5, 2, 'REY', 8),
	(5, 2, 'RETD', 0),
	(5, 2, 'TO', 0),
	(178, 2, 'RY', 64),
	(178, 2, 'RTD', 0),
	(178, 2, 'REC', 2),
	(178, 2, 'REY', 49),
	(178, 2, 'RETD', 0),
	(178, 2, 'TO', 0),
	(74, 2, 'RY', 55),
	(74, 2, 'RTD', 1),
	(74, 2, 'REC', 1),
	(74, 2, 'REY', -3),
	(74, 2, 'RETD', 0),
	(74, 2, 'TO', 0),
	(9, 2, 'RY', 88),
	(9, 2, 'RTD', 0),
	(9, 2, 'REC', 3),
	(9, 2, 'REY', 17),
	(9, 2, 'RETD', 0),
	(9, 2, 'TO', 0),
	(12, 2, 'RY', 86),
	(12, 2, 'RTD', 0),
	(12, 2, 'REC', 2),
	(12, 2, 'REY', 9),
	(12, 2, 'RETD', 0),
	(12, 2, 'TO', 0),
	(85, 2, 'RY', 32),
	(85, 2, 'RTD', 1),
	(85, 2, 'REC', 0),
	(85, 2, 'REY', 0),
	(85, 2, 'RETD', 0),
	(85, 2, 'TO', 0),
	(149, 2, 'RY', 7),
	(149, 2, 'RTD', 0),
	(149, 2, 'REC', 3),
	(149, 2, 'REY', 20),
	(149, 2, 'RETD', 1),
	(149, 2, 'TO', 0),
	(97, 2, 'RY', 23),
	(97, 2, 'RTD', 1),
	(97, 2, 'REC', 2),
	(97, 2, 'REY', 4),
	(97, 2, 'RETD', 0),
	(97, 2, 'TO', 0),
	(6, 2, 'RY', 84),
	(6, 2, 'RTD', 0),
	(6, 2, 'REC', 0),
	(6, 2, 'REY', 0),
	(6, 2, 'RETD', 0),
	(6, 2, 'TO', 0),
	(168, 2, 'RY', 46),
	(168, 2, 'RTD', 0),
	(168, 2, 'REC', 6),
	(168, 2, 'REY', 36),
	(168, 2, 'RETD', 0),
	(168, 2, 'TO', 0),
	(177, 2, 'RY', 1),
	(177, 2, 'RTD', 0),
	(177, 2, 'REC', 8),
	(177, 2, 'REY', 74),
	(177, 2, 'RETD', 0),
	(177, 2, 'TO', 0),
	(62, 2, 'RY', 12),
	(62, 2, 'RTD', 0),
	(62, 2, 'REC', 5),
	(62, 2, 'REY', 60),
	(62, 2, 'RETD', 0),
	(62, 2, 'TO', 0),
	(7, 2, 'RY', 38),
	(7, 2, 'RTD', 0),
	(7, 2, 'REC', 6),
	(7, 2, 'REY', 32),
	(7, 2, 'RETD', 0),
	(7, 2, 'TO', 0),
	(87, 2, 'RY', 4),
	(87, 2, 'RTD', 1),
	(87, 2, 'REC', 0),
	(87, 2, 'REY', 0),
	(87, 2, 'RETD', 0),
	(87, 2, 'TO', 0),
	(31, 2, 'RY', 61),
	(31, 2, 'RTD', 0),
	(31, 2, 'REC', 0),
	(31, 2, 'REY', 0),
	(31, 2, 'RETD', 0),
	(31, 2, 'TO', 0),
	(93, 2, 'RY', 48),
	(93, 2, 'RTD', 0),
	(93, 2, 'REC', 1),
	(93, 2, 'REY', 13),
	(93, 2, 'RETD', 0),
	(93, 2, 'TO', 0),
	(35, 2, 'RY', 34),
	(35, 2, 'RTD', 0),
	(35, 2, 'REC', 2),
	(35, 2, 'REY', 16),
	(35, 2, 'RETD', 0),
	(35, 2, 'TO', 0),
	(167, 2, 'RY', 47),
	(167, 2, 'RTD', 0),
	(167, 2, 'REC', 0),
	(167, 2, 'REY', 0),
	(167, 2, 'RETD', 0),
	(167, 2, 'TO', 0),
	(176, 2, 'RY', 41),
	(176, 2, 'RTD', 0),
	(176, 2, 'REC', 0),
	(176, 2, 'REY', 0),
	(176, 2, 'RETD', 0),
	(176, 2, 'TO', 0),
	(140, 2, 'RY', 12),
	(140, 2, 'RTD', 0),
	(140, 2, 'REC', 2),
	(140, 2, 'REY', 28),
	(140, 2, 'RETD', 0),
	(140, 2, 'TO', 0),
	(104, 2, 'RY', 37),
	(104, 2, 'RTD', 0),
	(104, 2, 'REC', 1),
	(104, 2, 'REY', 2),
	(104, 2, 'RETD', 0),
	(104, 2, 'TO', 1),
	(111, 2, 'RY', 37),
	(111, 2, 'RTD', 0),
	(111, 2, 'REC', 0),
	(111, 2, 'REY', 0),
	(111, 2, 'RETD', 0),
	(111, 2, 'TO', 0),
	(145, 2, 'RY', 14),
	(145, 2, 'RTD', 0),
	(145, 2, 'REC', 2),
	(145, 2, 'REY', 19),
	(145, 2, 'RETD', 0),
	(145, 2, 'TO', 0),
	(3, 2, 'RY', 28),
	(3, 2, 'RTD', 0),
	(3, 2, 'REC', 0),
	(3, 2, 'REY', 0),
	(3, 2, 'RETD', 0),
	(3, 2, 'TO', 0),
	(83, 2, 'RY', 12),
	(83, 2, 'RTD', 0),
	(83, 2, 'REC', 1),
	(83, 2, 'REY', 15),
	(83, 2, 'RETD', 0),
	(83, 2, 'TO', 0),
	(146, 2, 'RY', 19),
	(146, 2, 'RTD', 0),
	(146, 2, 'REC', 0),
	(146, 2, 'REY', 0),
	(146, 2, 'RETD', 0),
	(146, 2, 'TO', 0),
	(143, 2, 'RY', 13),
	(143, 2, 'RTD', 0),
	(143, 2, 'REC', 1),
	(143, 2, 'REY', 3),
	(143, 2, 'RETD', 0),
	(143, 2, 'TO', 0),
	(57, 2, 'RY', 13),
	(57, 2, 'RTD', 0),
	(57, 2, 'REC', 0),
	(57, 2, 'REY', 0),
	(57, 2, 'RETD', 0),
	(57, 2, 'TO', 0),
	(43, 2, 'RY', 0),
	(43, 2, 'RTD', 0),
	(43, 2, 'REC', 7),
	(43, 2, 'REY', 109),
	(43, 2, 'RETD', 2),
	(43, 2, 'TO', 0),
	(76, 2, 'RY', 0),
	(76, 2, 'RTD', 0),
	(76, 2, 'REC', 8),
	(76, 2, 'REY', 153),
	(76, 2, 'RETD', 1),
	(76, 2, 'TO', 0),
	(45, 2, 'RY', 0),
	(45, 2, 'RTD', 0),
	(45, 2, 'REC', 7),
	(45, 2, 'REY', 125),
	(45, 2, 'RETD', 1),
	(45, 2, 'TO', 0),
	(86, 2, 'RY', 0),
	(86, 2, 'RTD', 0),
	(86, 2, 'REC', 8),
	(86, 2, 'REY', 179),
	(86, 2, 'RETD', 0),
	(86, 2, 'TO', 0),
	(17, 2, 'RY', 9),
	(17, 2, 'RTD', 0),
	(17, 2, 'REC', 5),
	(17, 2, 'REY', 99),
	(17, 2, 'RETD', 1),
	(17, 2, 'TO', 0),
	(24, 2, 'RY', 0),
	(24, 2, 'RTD', 0),
	(24, 2, 'REC', 7),
	(24, 2, 'REY', 104),
	(24, 2, 'RETD', 1),
	(24, 2, 'TO', 0),
	(63, 2, 'RY', 0),
	(63, 2, 'RTD', 0),
	(63, 2, 'REC', 4),
	(63, 2, 'REY', 92),
	(63, 2, 'RETD', 1),
	(63, 2, 'TO', 0),
	(100, 2, 'RY', -8),
	(100, 2, 'RTD', 0),
	(100, 2, 'REC', 8),
	(100, 2, 'REY', 92),
	(100, 2, 'RETD', 1),
	(100, 2, 'TO', 1),
	(123, 2, 'RY', 0),
	(123, 2, 'RTD', 0),
	(123, 2, 'REC', 4),
	(123, 2, 'REY', 82),
	(123, 2, 'RETD', 1),
	(123, 2, 'TO', 0),
	(27, 2, 'RY', 0),
	(27, 2, 'RTD', 0),
	(27, 2, 'REC', 4),
	(27, 2, 'REY', 74),
	(27, 2, 'RETD', 1),
	(27, 2, 'TO', 0),
	(78, 2, 'RY', 0),
	(78, 2, 'RTD', 0),
	(78, 2, 'REC', 7),
	(78, 2, 'REY', 72),
	(78, 2, 'RETD', 1),
	(78, 2, 'TO', 0),
	(11, 2, 'RY', 0),
	(11, 2, 'RTD', 0),
	(11, 2, 'REC', 8),
	(11, 2, 'REY', 68),
	(11, 2, 'RETD', 1),
	(11, 2, 'TO', 0),
	(42, 2, 'RY', 0),
	(42, 2, 'RTD', 0),
	(42, 2, 'REC', 7),
	(42, 2, 'REY', 67),
	(42, 2, 'RETD', 1),
	(42, 2, 'TO', 0),
	(30, 2, 'RY', 0),
	(30, 2, 'RTD', 0),
	(30, 2, 'REC', 8),
	(30, 2, 'REY', 120),
	(30, 2, 'RETD', 0),
	(30, 2, 'TO', 0),
	(113, 2, 'RY', 9),
	(113, 2, 'RTD', 0),
	(113, 2, 'REC', 6),
	(113, 2, 'REY', 106),
	(113, 2, 'RETD', 0),
	(113, 2, 'TO', 0),
	(68, 2, 'RY', 0),
	(68, 2, 'RTD', 0),
	(68, 2, 'REC', 5),
	(68, 2, 'REY', 53),
	(68, 2, 'RETD', 1),
	(68, 2, 'TO', 0),
	(121, 2, 'RY', 0),
	(121, 2, 'RTD', 0),
	(121, 2, 'REC', 9),
	(121, 2, 'REY', 109),
	(121, 2, 'RETD', 0),
	(121, 2, 'TO', 1),
	(187, 2, 'RY', 0),
	(187, 2, 'RTD', 0),
	(187, 2, 'REC', 6),
	(187, 2, 'REY', 46),
	(187, 2, 'RETD', 1),
	(187, 2, 'TO', 0),
	(37, 2, 'RY', 0),
	(37, 2, 'RTD', 0),
	(37, 2, 'REC', 6),
	(37, 2, 'REY', 100),
	(37, 2, 'RETD', 0),
	(37, 2, 'TO', 0),
	(49, 2, 'RY', 19),
	(49, 2, 'RTD', 0),
	(49, 2, 'REC', 5),
	(49, 2, 'REY', 81),
	(49, 2, 'RETD', 0),
	(49, 2, 'TO', 1),
	(58, 2, 'RY', 0),
	(58, 2, 'RTD', 0),
	(58, 2, 'REC', 7),
	(58, 2, 'REY', 96),
	(58, 2, 'RETD', 0),
	(58, 2, 'TO', 1),
	(88, 2, 'RY', 0),
	(88, 2, 'RTD', 0),
	(88, 2, 'REC', 5),
	(88, 2, 'REY', 95),
	(88, 2, 'RETD', 0),
	(88, 2, 'TO', 0),
	(46, 2, 'RY', 19),
	(46, 2, 'RTD', 1),
	(46, 2, 'REC', 2),
	(46, 2, 'REY', 14),
	(46, 2, 'RETD', 0),
	(46, 2, 'TO', 0),
	(189, 2, 'RY', 0),
	(189, 2, 'RTD', 0),
	(189, 2, 'REC', 5),
	(189, 2, 'REY', 86),
	(189, 2, 'RETD', 0),
	(189, 2, 'TO', 0),
	(59, 2, 'RY', 0),
	(59, 2, 'RTD', 0),
	(59, 2, 'REC', 4),
	(59, 2, 'REY', 84),
	(59, 2, 'RETD', 0),
	(59, 2, 'TO', 0),
	(163, 2, 'RY', 0),
	(163, 2, 'RTD', 0),
	(163, 2, 'REC', 7),
	(163, 2, 'REY', 76),
	(163, 2, 'RETD', 0),
	(163, 2, 'TO', 0),
	(147, 2, 'RY', 0),
	(147, 2, 'RTD', 0),
	(147, 2, 'REC', 8),
	(147, 2, 'REY', 72),
	(147, 2, 'RETD', 0),
	(147, 2, 'TO', 0),
	(32, 2, 'RY', 0),
	(32, 2, 'RTD', 0),
	(32, 2, 'REC', 3),
	(32, 2, 'REY', 66),
	(32, 2, 'RETD', 0),
	(32, 2, 'TO', 0),
	(94, 2, 'RY', 0),
	(94, 2, 'RTD', 0),
	(94, 2, 'REC', 6),
	(94, 2, 'REY', 64),
	(94, 2, 'RETD', 0),
	(94, 2, 'TO', 0),
	(105, 2, 'RY', 0),
	(105, 2, 'RTD', 0),
	(105, 2, 'REC', 4),
	(105, 2, 'REY', 62),
	(105, 2, 'RETD', 0),
	(105, 2, 'TO', 0),
	(115, 2, 'RY', 3),
	(115, 2, 'RTD', 0),
	(115, 2, 'REC', 2),
	(115, 2, 'REY', 57),
	(115, 2, 'RETD', 0),
	(115, 2, 'TO', 0),
	(80, 2, 'RY', 0),
	(80, 2, 'RTD', 0),
	(80, 2, 'REC', 2),
	(80, 2, 'REY', 58),
	(80, 2, 'RETD', 0),
	(80, 2, 'TO', 0),
	(41, 2, 'RY', 0),
	(41, 2, 'RTD', 0),
	(41, 2, 'REC', 7),
	(41, 2, 'REY', 48),
	(41, 2, 'RETD', 0),
	(41, 2, 'TO', 0),
	(110, 2, 'RY', 0),
	(110, 2, 'RTD', 0),
	(110, 2, 'REC', 5),
	(110, 2, 'REY', 47),
	(110, 2, 'RETD', 0),
	(110, 2, 'TO', 0),
	(51, 2, 'RY', 0),
	(51, 2, 'RTD', 0),
	(51, 2, 'REC', 3),
	(51, 2, 'REY', 46),
	(51, 2, 'RETD', 0),
	(51, 2, 'TO', 0),
	(154, 2, 'RY', 0),
	(154, 2, 'RTD', 0),
	(154, 2, 'REC', 3),
	(154, 2, 'REY', 44),
	(154, 2, 'RETD', 0),
	(154, 2, 'TO', 0),
	(72, 2, 'RY', 0),
	(72, 2, 'RTD', 0),
	(72, 2, 'REC', 5),
	(72, 2, 'REY', 42),
	(72, 2, 'RETD', 0),
	(72, 2, 'TO', 0),
	(15, 2, 'RY', 0),
	(15, 2, 'RTD', 0),
	(15, 2, 'REC', 3),
	(15, 2, 'REY', 36),
	(15, 2, 'RETD', 0),
	(15, 2, 'TO', 0),
	(77, 2, 'RY', 6),
	(77, 2, 'RTD', 0),
	(77, 2, 'REC', 2),
	(77, 2, 'REY', 29),
	(77, 2, 'RETD', 0),
	(77, 2, 'TO', 0),
	(40, 2, 'RY', 0),
	(40, 2, 'RTD', 0),
	(40, 2, 'REC', 3),
	(40, 2, 'REY', 33),
	(40, 2, 'RETD', 0),
	(40, 2, 'TO', 0),
	(120, 2, 'RY', 0),
	(120, 2, 'RTD', 0),
	(120, 2, 'REC', 3),
	(120, 2, 'REY', 33),
	(120, 2, 'RETD', 0),
	(120, 2, 'TO', 0),
	(151, 2, 'RY', 3),
	(151, 2, 'RTD', 0),
	(151, 2, 'REC', 2),
	(151, 2, 'REY', 30),
	(151, 2, 'RETD', 0),
	(151, 2, 'TO', 0),
	(26, 2, 'RY', 0),
	(26, 2, 'RTD', 0),
	(26, 2, 'REC', 3),
	(26, 2, 'REY', 31),
	(26, 2, 'RETD', 0),
	(26, 2, 'TO', 0),
	(73, 2, 'RY', 0),
	(73, 2, 'RTD', 0),
	(73, 2, 'REC', 3),
	(73, 2, 'REY', 29),
	(73, 2, 'RETD', 0),
	(73, 2, 'TO', 0),
	(54, 2, 'RY', 0),
	(54, 2, 'RTD', 0),
	(54, 2, 'REC', 3),
	(54, 2, 'REY', 28),
	(54, 2, 'RETD', 0),
	(54, 2, 'TO', 0),
	(112, 2, 'RY', 0),
	(112, 2, 'RTD', 0),
	(112, 2, 'REC', 1),
	(112, 2, 'REY', 26),
	(112, 2, 'RETD', 0),
	(112, 2, 'TO', 0),
	(16, 2, 'RY', 0),
	(16, 2, 'RTD', 0),
	(16, 2, 'REC', 2),
	(16, 2, 'REY', 24),
	(16, 2, 'RETD', 0),
	(16, 2, 'TO', 0),
	(117, 2, 'RY', 0),
	(117, 2, 'RTD', 0),
	(117, 2, 'REC', 1),
	(117, 2, 'REY', 18),
	(117, 2, 'RETD', 0),
	(117, 2, 'TO', 0),
	(139, 2, 'RY', 0),
	(139, 2, 'RTD', 0),
	(139, 2, 'REC', 2),
	(139, 2, 'REY', 14),
	(139, 2, 'RETD', 0),
	(139, 2, 'TO', 0),
	(158, 2, 'RY', 0),
	(158, 2, 'RTD', 0),
	(158, 2, 'REC', 2),
	(158, 2, 'REY', 12),
	(158, 2, 'RETD', 0),
	(158, 2, 'TO', 0),
	(171, 2, 'RY', 0),
	(171, 2, 'RTD', 0),
	(171, 2, 'REC', 1),
	(171, 2, 'REY', 11),
	(171, 2, 'RETD', 0),
	(171, 2, 'TO', 0),
	(173, 2, 'RY', 7),
	(173, 2, 'RTD', 0),
	(173, 2, 'REC', 0),
	(173, 2, 'REY', 0),
	(173, 2, 'RETD', 0),
	(173, 2, 'TO', 0),
	(89, 2, 'RY', 0),
	(89, 2, 'RTD', 0),
	(89, 2, 'REC', 1),
	(89, 2, 'REY', 4),
	(89, 2, 'RETD', 0),
	(89, 2, 'TO', 0),
	(67, 2, 'RY', 0),
	(67, 2, 'RTD', 0),
	(67, 2, 'REC', 0),
	(67, 2, 'REY', 0),
	(67, 2, 'RETD', 0),
	(67, 2, 'TO', 0),
	(65, 2, 'RY', 0),
	(65, 2, 'RTD', 0),
	(65, 2, 'REC', 5),
	(65, 2, 'REY', 54),
	(65, 2, 'RETD', 3),
	(65, 2, 'TO', 0),
	(179, 2, 'RY', 0),
	(179, 2, 'RTD', 0),
	(179, 2, 'REC', 4),
	(179, 2, 'REY', 84),
	(179, 2, 'RETD', 2),
	(179, 2, 'TO', 0),
	(114, 2, 'RY', 0),
	(114, 2, 'RTD', 0),
	(114, 2, 'REC', 8),
	(114, 2, 'REY', 130),
	(114, 2, 'RETD', 1),
	(114, 2, 'TO', 0),
	(53, 2, 'RY', 0),
	(53, 2, 'RTD', 0),
	(53, 2, 'REC', 12),
	(53, 2, 'REY', 105),
	(53, 2, 'RETD', 1),
	(53, 2, 'TO', 0),
	(21, 2, 'RY', 0),
	(21, 2, 'RTD', 0),
	(21, 2, 'REC', 9),
	(21, 2, 'REY', 90),
	(21, 2, 'RETD', 1),
	(21, 2, 'TO', 0),
	(185, 2, 'RY', 0),
	(185, 2, 'RTD', 0),
	(185, 2, 'REC', 9),
	(185, 2, 'REY', 88),
	(185, 2, 'RETD', 1),
	(185, 2, 'TO', 1),
	(133, 2, 'RY', 0),
	(133, 2, 'RTD', 0),
	(133, 2, 'REC', 5),
	(133, 2, 'REY', 72),
	(133, 2, 'RETD', 1),
	(133, 2, 'TO', 0),
	(109, 2, 'RY', 0),
	(109, 2, 'RTD', 0),
	(109, 2, 'REC', 4),
	(109, 2, 'REY', 57),
	(109, 2, 'RETD', 1),
	(109, 2, 'TO', 0),
	(102, 2, 'RY', 0),
	(102, 2, 'RTD', 0),
	(102, 2, 'REC', 6),
	(102, 2, 'REY', 83),
	(102, 2, 'RETD', 0),
	(102, 2, 'TO', 0),
	(71, 2, 'RY', 0),
	(71, 2, 'RTD', 0),
	(71, 2, 'REC', 2),
	(71, 2, 'REY', 13),
	(71, 2, 'RETD', 1),
	(71, 2, 'TO', 0),
	(55, 2, 'RY', 0),
	(55, 2, 'RTD', 0),
	(55, 2, 'REC', 6),
	(55, 2, 'REY', 65),
	(55, 2, 'RETD', 0),
	(55, 2, 'TO', 0),
	(116, 2, 'RY', 0),
	(116, 2, 'RTD', 0),
	(116, 2, 'REC', 4),
	(116, 2, 'REY', 62),
	(116, 2, 'RETD', 0),
	(116, 2, 'TO', 0),
	(44, 2, 'RY', 0),
	(44, 2, 'RTD', 0),
	(44, 2, 'REC', 5),
	(44, 2, 'REY', 42),
	(44, 2, 'RETD', 0),
	(44, 2, 'TO', 0),
	(172, 2, 'RY', 0),
	(172, 2, 'RTD', 0),
	(172, 2, 'REC', 4),
	(172, 2, 'REY', 30),
	(172, 2, 'RETD', 0),
	(172, 2, 'TO', 0),
	(38, 2, 'RY', 0),
	(38, 2, 'RTD', 0),
	(38, 2, 'REC', 1),
	(38, 2, 'REY', 29),
	(38, 2, 'RETD', 0),
	(38, 2, 'TO', 0),
	(92, 2, 'RY', 0),
	(92, 2, 'RTD', 0),
	(92, 2, 'REC', 0),
	(92, 2, 'REY', 0),
	(92, 2, 'RETD', 0),
	(92, 2, 'TO', 0),
	(164, 2, 'SK', 4),
	(164, 2, 'TOC', 2),
	(164, 2, 'DTD', 0),
	(164, 2, 'SF', 0),
	(164, 2, 'YA', 316),
	(164, 2, 'PA', 15),
	(106, 2, 'SK', 4),
	(106, 2, 'TOC', 2),
	(106, 2, 'DTD', 1),
	(106, 2, 'SF', 0),
	(106, 2, 'YA', 304),
	(106, 2, 'PA', 16),
	(107, 2, 'SK', 3),
	(107, 2, 'TOC', 0),
	(107, 2, 'DTD', 0),
	(107, 2, 'SF', 0),
	(107, 2, 'YA', 410),
	(107, 2, 'PA', 28),
	(132, 2, 'SK', 4),
	(132, 2, 'TOC', 2),
	(132, 2, 'DTD', 0),
	(132, 2, 'SF', 0),
	(132, 2, 'YA', 295),
	(132, 2, 'PA', 13),
	(186, 2, 'SK', 3),
	(186, 2, 'TOC', 1),
	(186, 2, 'DTD', 0),
	(186, 2, 'SF', 0),
	(186, 2, 'YA', 353),
	(186, 2, 'PA', 30),
	(144, 2, 'SK', 1),
	(144, 2, 'TOC', 0),
	(144, 2, 'DTD', 0),
	(144, 2, 'SF', 0),
	(144, 2, 'YA', 380),
	(144, 2, 'PA', 39),
	(141, 2, 'SK', 1),
	(141, 2, 'TOC', 2),
	(141, 2, 'DTD', 0),
	(141, 2, 'SF', 0),
	(141, 2, 'YA', 410),
	(141, 2, 'PA', 26),
	(124, 2, 'SK', 3),
	(124, 2, 'TOC', 3),
	(124, 2, 'DTD', 0),
	(124, 2, 'SF', 1),
	(124, 2, 'YA', 175),
	(124, 2, 'PA', 11),
	(165, 2, 'SK', 2),
	(165, 2, 'TOC', 1),
	(165, 2, 'DTD', 0),
	(165, 2, 'SF', 0),
	(165, 2, 'YA', 479),
	(165, 2, 'PA', 20),
	(119, 2, 'SK', 2),
	(119, 2, 'TOC', 2),
	(119, 2, 'DTD', 0),
	(119, 2, 'SF', 0),
	(119, 2, 'YA', 522),
	(119, 2, 'PA', 28),
	(103, 2, 'SK', 2),
	(103, 2, 'TOC', 1),
	(103, 2, 'DTD', 1),
	(103, 2, 'SF', 0),
	(103, 2, 'YA', 269),
	(103, 2, 'PA', 35),
	(130, 2, 'SK', 3),
	(130, 2, 'TOC', 1),
	(130, 2, 'DTD', 0),
	(130, 2, 'SF', 0),
	(130, 2, 'YA', 310),
	(130, 2, 'PA', 34),
	(183, 2, 'SK', 4),
	(183, 2, 'TOC', 2),
	(183, 2, 'DTD', 0),
	(183, 2, 'SF', 0),
	(183, 2, 'YA', 349),
	(183, 2, 'PA', 17),
	(162, 2, 'SK', 1),
	(162, 2, 'TOC', 1),
	(162, 2, 'DTD', 0),
	(162, 2, 'SF', 0),
	(162, 2, 'YA', 449),
	(162, 2, 'PA', 37),
	(96, 2, 'SK', 7),
	(96, 2, 'TOC', 2),
	(96, 2, 'DTD', 0),
	(96, 2, 'SF', 1),
	(96, 2, 'YA', 319),
	(96, 2, 'PA', 21),
	(156, 2, 'SK', 1),
	(156, 2, 'TOC', 1),
	(156, 2, 'DTD', 0),
	(156, 2, 'SF', 0),
	(156, 2, 'YA', 277),
	(156, 2, 'PA', 13),
	(108, 2, 'SK', 1),
	(108, 2, 'TOC', 0),
	(108, 2, 'DTD', 0),
	(108, 2, 'SF', 0),
	(108, 2, 'YA', 464),
	(108, 2, 'PA', 30),
	(142, 2, 'SK', 5),
	(142, 2, 'TOC', 4),
	(142, 2, 'DTD', 0),
	(142, 2, 'SF', 0),
	(142, 2, 'YA', 427),
	(142, 2, 'PA', 17),
	(155, 2, 'SK', 2),
	(155, 2, 'TOC', 2),
	(155, 2, 'DTD', 0),
	(155, 2, 'SF', 0),
	(155, 2, 'YA', 480),
	(155, 2, 'PA', 30),
	(125, 2, 'MFG', 0),
	(125, 2, 'FG', 4),
	(125, 2, 'PAT', 3),
	(181, 2, 'MFG', 0),
	(181, 2, 'FG', 4),
	(181, 2, 'PAT', 3),
	(157, 2, 'MFG', 0),
	(157, 2, 'FG', 3),
	(157, 2, 'PAT', 3),
	(166, 2, 'MFG', 0),
	(166, 2, 'FG', 2),
	(166, 2, 'PAT', 4),
	(150, 2, 'MFG', 0),
	(150, 2, 'FG', 2),
	(150, 2, 'PAT', 4),
	(152, 2, 'MFG', 0),
	(152, 2, 'FG', 3),
	(152, 2, 'PAT', 1),
	(95, 2, 'MFG', 0),
	(95, 2, 'FG', 3),
	(95, 2, 'PAT', 0),
	(160, 2, 'MFG', 0),
	(160, 2, 'FG', 1),
	(160, 2, 'PAT', 4),
	(127, 2, 'MFG', 0),
	(127, 2, 'FG', 1),
	(127, 2, 'PAT', 4),
	(159, 2, 'MFG', 0),
	(159, 2, 'FG', 1),
	(159, 2, 'PAT', 3),
	(98, 2, 'MFG', 0),
	(98, 2, 'FG', 1),
	(98, 2, 'PAT', 3),
	(128, 2, 'MFG', 1),
	(128, 2, 'FG', 0),
	(128, 2, 'PAT', 3);
