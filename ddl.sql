# MySQL
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
  num_teams INT NOT NULL DEFAULT 0,
  max_teams INT NOT NULL,
  is_full BOOLEAN AS (num_teams = max_teams),
  PRIMARY KEY (league_id),
  UNIQUE KEY (name),
  FOREIGN KEY (commissioner) REFERENCES user(user_id)
);

SET @MAX_ROSTER_SIZE = 17;
CREATE TABLE fantasy_team (
  fantasy_team_id INT AUTO_INCREMENT,
  league_id INT,
  manager INT,
  name VARCHAR(30) NOT NULL,
  abbreviation VARCHAR(4),
  roster_size INT NOT NULL DEFAULT 0,
  roster_full BOOLEAN AS (roster_size = @MAX_ROSTER_SIZE),
  PRIMARY KEY (fantasy_team_id),
  UNIQUE KEY (league_id, manager),
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
  PRIMARY KEY (abbreviation),
  CHECK (1 <= bye_week <= 17)
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

CREATE TABLE lineup_position (
  lineup_posn_id INT AUTO_INCREMENT,
  abbreviation VARCHAR(4),
  `position` VARCHAR(4),
  slot_description VARCHAR(30) NOT NULL,
  PRIMARY KEY (lineup_posn_id),
  FOREIGN KEY (`position`) REFERENCES `position`(abbreviation)
);

CREATE TABLE lineup (
  week INT NOT NULL,
  fantasy_team_id INT NOT NULL,
  position_slot INT NOT NULL,
  player_id INT NOT NULL,
  UNIQUE KEY (week, fantasy_team_id, player_id),
  FOREIGN KEY (fantasy_team_id) REFERENCES fantasy_team(fantasy_team_id),
  FOREIGN KEY (position_slot) REFERENCES lineup_position(lineup_posn_id),
  FOREIGN KEY (player_id) REFERENCES player(player_id),
  CHECK (1 <= week <= 17)
);

CREATE TABLE matchup (
  matchup_id INT AUTO_INCREMENT,
  week INT NOT NULL,
  home_team INT,
  away_team INT,
  PRIMARY KEY (matchup_id),
  FOREIGN KEY (home_team) REFERENCES fantasy_team(fantasy_team_id),
  FOREIGN KEY (away_team) REFERENCES fantasy_team(fantasy_team_id),
  CHECK (1 <= week <= 17)
);

CREATE TABLE scoring (
  abbreviation VARCHAR(5),
  statistic VARCHAR(40),
  points DECIMAL(3, 2),
  PRIMARY KEY (abbreviation)
);

CREATE TABLE player_performance (
  performance_id INT AUTO_INCREMENT,
  player_id INT,
  week INT NOT NULL,
  statistic VARCHAR(5) NOT NULL,
  quantity INT NOT NULL,
  PRIMARY KEY (performance_id),
  UNIQUE KEY (player_id, week, statistic),
  FOREIGN KEY (player_id) REFERENCES player(player_id),
  FOREIGN KEY (statistic) REFERENCES scoring(abbreviation),
  CHECK (1 <= week <= 17)
);
