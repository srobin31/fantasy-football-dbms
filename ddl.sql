DROP DATABASE fantasy_football;
CREATE DATABASE fantasy_football;
USE fantasy_football;

CREATE TABLE user (
  user_id INT AUTO_INCREMENT,
  first_name VARCHAR(20) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(50) NOT NULL,
  password VARCHAR(50) NOT NULL,
  PRIMARY KEY (user_id),
  UNIQUE KEY (email)
);

CREATE TABLE league (
  league_id INT AUTO_INCREMENT, 
  name VARCHAR(30) NOT NULL, 
  commissioner INT,
  num_teams INT NOT NULL, 
  is_full BOOLEAN NOT NULL DEFAULT FALSE,
  py_points DECIMAL(2,2) NOT NULL DEFAULT 0.04,
  ptd_points INT NOT NULL DEFAULT 4,
  ry_points DECIMAL(1,1) NOT NULL DEFAULT 0.1,
  rtd_points INT NOT NULL DEFAULT 6,
  rec_points DECIMAL(2,1) NOT NULL DEFAULT 0,
  rey_points DECIMAL(1,1) NOT NULL DEFAULT 0.1,
  retd_points INT NOT NULL DEFAULT 6,
  to_points INT NOT NULL DEFAULT -2,
  sk_points INT NOT NULL DEFAULT 1,
  toc_points INT NOT NULL DEFAULT 2,
  pa0_points INT NOT NULL DEFAULT 5,
  pa1_points INT NOT NULL DEFAULT 4,
  pa7_points INT NOT NULL DEFAULT 3,
  pa14_points INT NOT NULL DEFAULT 1,
  pa28_points INT NOT NULL DEFAULT -1,
  pa35_points INT NOT NULL DEFAULT -3,
  pa46_points INT NOT NULL DEFAULT -5,
  ya100_points INT NOT NULL DEFAULT 5,
  ya199_points INT NOT NULL DEFAULT 3,
  ya299_points INT NOT NULL DEFAULT 1,
  ya399_points INT NOT NULL DEFAULT -1,
  ya449_points INT NOT NULL DEFAULT -3,
  ya499_points INT NOT NULL DEFAULT -5,
  ya549_points INT NOT NULL DEFAULT -6,
  ya550_points INT NOT NULL DEFAULT -7,
  fg_points INT NOT NULL DEFAULT 3,
  mfg_points INT NOT NULL DEFAULT -1,
  ep_points INT NOT NULL DEFAULT 3,
  PRIMARY KEY (league_id),
  UNIQUE KEY (name),
  FOREIGN KEY (commissioner) REFERENCES user(user_id)
);

CREATE TABLE fantasy_team (
  fantasy_team_id INT AUTO_INCREMENT, 
  league_id INT, 
  manager INT, 
  name VARCHAR(30) NOT NULL, 
  abbreviation VARCHAR(4),
  PRIMARY KEY (fantasy_team_id),
  FOREIGN KEY (league_id) REFERENCES league(league_id),
  FOREIGN KEY (manager) REFERENCES user(user_id)
);

CREATE TABLE `position` (
  abbreviation VARCHAR(4),
  name VARCHAR(30) NOT NULL,
  PRIMARY KEY (abbreviation)
);

CREATE TABLE nfl_team (
  abbreviation VARCHAR(3),
  city VARCHAR(20) NOT NULL,
  name VARCHAR(20) NOT NULL,
  bye_week INT NOT NULL,
  PRIMARY KEY (abbreviation)
);

CREATE TABLE player (
  player_id INT AUTO_INCREMENT,
  first_name VARCHAR(20) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  position VARCHAR(4),
  nfl_team VARCHAR(3),
  PRIMARY KEY (player_id),
  FOREIGN KEY (position) REFERENCES `position`(abbreviation),
  FOREIGN KEY (nfl_team) REFERENCES nfl_team(abbreviation)
);

CREATE TABLE roster (
  fantasy_team_id INT,
  player_id INT,
  FOREIGN KEY (fantasy_team_id) REFERENCES fantasy_team(fantasy_team_id),
  FOREIGN KEY (player_id) REFERENCES player(player_id),
  PRIMARY KEY (fantasy_team_id, player_id)
);

CREATE TABLE weekly_lineup (
  lineup_id INT AUTO_INCREMENT,
  week INT NOT NULL,
  fantasy_team_id INT,
  qb INT,
  rb1 INT,
  rb2 INT,
  wr1 INT,
  wr2 INT,
  te INT,
  flex INT,
  dst INT,
  k INT,
  PRIMARY KEY (lineup_id),
  FOREIGN KEY (fantasy_team_id) REFERENCES fantasy_team(fantasy_team_id),
  FOREIGN KEY (qb) REFERENCES player(player_id),
  FOREIGN KEY (rb1) REFERENCES player(player_id),
  FOREIGN KEY (rb2) REFERENCES player(player_id),
  FOREIGN KEY (wr1) REFERENCES player(player_id),
  FOREIGN KEY (wr2) REFERENCES player(player_id),
  FOREIGN KEY (te) REFERENCES player(player_id),
  FOREIGN KEY (flex) REFERENCES player(player_id),
  FOREIGN KEY (dst) REFERENCES player(player_id),
  FOREIGN KEY (k) REFERENCES player(player_id)
);

CREATE TABLE matchup (
  matchup_id INT AUTO_INCREMENT,
  week INT NOT NULL,
  home_team INT,
  away_team INT,
  home_team_score DECIMAL(4,1) NOT NULL DEFAULT 0.0,
  away_team_score DECIMAL(4,1) NOT NULL DEFAULT 0.0,
  PRIMARY KEY (matchup_id),
  FOREIGN KEY (home_team) REFERENCES fantasy_team(fantasy_team_id),
  FOREIGN KEY (away_team) REFERENCES fantasy_team(fantasy_team_id)
);

CREATE TABLE player_performance (
  performance_id INT AUTO_INCREMENT,
  player_id INT,
  week INT NOT NULL,
  passing_yards INT,
  passing_tds INT,
  rushing_yards INT,
  rushing_tds INT,
  receptions INT,
  receiving_yards INT,
  receiving_tds INT,
  turnovers INT,
  sacks INT,
  turnovers_created INT,
  yards_allowed INT,
  points_allowed INT,
  field_goals INT,
  missed_field_goals INT,
  extra_points INT,
  PRIMARY KEY (performance_id),
  UNIQUE KEY (player_id, week),
  FOREIGN KEY (player_id) REFERENCES player(player_id)
);
  