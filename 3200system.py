#!/usr/bin/env python3

import pymysql

HOST = 'localhost'
USER = 'root'
PASSWORD = ''
DB = 'fantasy_football'

TASKS = '''TASKS (1-12) / REPORTS (13-17)
0: Exit
1: Add user
2: Make a new fantasy league
3: Make a new fantasy team
4: Release a player from a fantasy team
5: Add a player to a fantasy team
6: Complete a trade between 2 fantasy teams
7: Modify a player's NFL team (as if they've been traded in real life)
8: Add a new weekly lineup
9: Insert a player's statistics
10: Produce a list of all players on a particular roster
11: Produce a list of all players not on a fantasy roster in a particular league
12: View scoreboard for a particular week of matchups
13: Produce a list of non-Quarterbacks sorted by who's averaged the most points per week
14: Produce a list of all players not in a starting lineup for a given week sorted by score
15: Find how many players of each possible FLEX position each fantasy team in a particular league has on its roster
16: Find which fantasy teams in a particular league have more than 2 players with the same bye week, specifying the week and player count
17: View standings for a particular league (wins, losses, points for, points against)'''

LINEUP = ['QB', 'RB1', 'RB2', 'WR1', 'WR2', 'TE', 'FLEX', 'D/ST', 'K']

# connect to the database
def db_connect():
    conn = pymysql.connect(host=HOST, user=USER, password=PASSWORD, db=DB, cursorclass=pymysql.cursors.DictCursor)
    return conn

# excecute given sql command
# return any query results
def execute_sql(sql):
    try:
        conn = db_connect()
        statements = sql.split(';')
        with conn.cursor() as cursor:
            for statement in statements:
                cursor.execute(statement)
        conn.commit()
        result = cursor.fetchall()
        return result
    except Exception as e:
        print(e)
    finally:
        conn.close()

# print id and email of each user
# return all user IDs
def display_users():
    print('USERS')
    print('ID\tUser Email')
    users = execute_sql('SELECT * FROM user')
    for user in users:
        print('{}\t{}'.format(user['user_id'], user['email']))
    return [u['user_id'] for u in users]

# print id and name of each league
# return all league IDs
def display_leagues():
    print('LEAGUES')
    print('ID\tLeague')
    leagues = execute_sql('SELECT * FROM league')
    for league in leagues:
        print('{}\t{}'.format(league['league_id'], league['name']))
    return [l['league_id'] for l in leagues]

# print id, league name, and manager of each fantasy team
# return all fantasy team IDs
def display_teams():
    print('FANTASY TEAMS')
    print('ID\tLeague\t\t\tManager Email')
    teams = execute_sql('SELECT fantasy_team_id, l.name, u.email FROM fantasy_team ft join league l on ft.league_id = l.league_id join user u on ft.manager = u.user_id')
    for team in teams:
        print('{}\t{}\t{}'.format(team['fantasy_team_id'], team['name'], team['email']))
    return [t['fantasy_team_id'] for t in teams]

# print all players on given fantasy team
# return all player IDs on a given fantasy team
def display_roster(team_id):
    print('ROSTER')
    print('ID\tTeam\tPos\tName')
    sql = 'SELECT r.player_id, nfl_team, position, CONCAT(first_name, " ", last_name) as name FROM roster r join player p on r.player_id = p.player_id WHERE fantasy_team_id = {}'.format(team_id)
    players = execute_sql(sql)
    for player in players:
        print('{}\t{}\t{}\t{}'.format(player['player_id'], player['nfl_team'], player['position'], player['name']))
    return [p['player_id'] for p in players]

# print all players not on fantasy teams in the given league
# return all player IDs of a league's free agents
def display_free_agents(league_id):
    print('FREE AGENTS')
    print('ID\tTeam\tPos\tName')
    sql = '''SELECT player_id, nfl_team, position, CONCAT(first_name, " ", last_name) as name
FROM player WHERE player_id not in (SELECT player_id FROM roster WHERE fantasy_team_id in (SELECT fantasy_team_id FROM fantasy_team where league_id = {}))'''.format(league_id)
    players = execute_sql(sql)
    for player in players:
        print('{}\t{}\t{}\t{}'.format(player['player_id'], player['nfl_team'], player['position'], player['name']))
    return [p['player_id'] for p in players]

# print all players
# return all player IDs
def display_players():
    print('PLAYERS')
    print('ID\tTeam\tPos\tName')
    sql = 'SELECT player_id, nfl_team, position, CONCAT(first_name, " ", last_name) as name FROM player'
    players = execute_sql(sql)
    for player in players:
        print('{}\t{}\t{}\t{}'.format(player['player_id'], player['nfl_team'], player['position'], player['name']))
    return [p['player_id'] for p in players]

# print all NFL teams
# return all NFL team abbreviations
def display_nfl_teams():
    print('NFL TEAMS')
    print('Abbreviation\tTeam')
    sql = 'SELECT abbreviation, CONCAT(city, " ", name) as team FROM nfl_team'
    teams = execute_sql(sql)
    for team in teams:
        print('{}\t{}'.format(team['abbreviation'], team['team']))
    return [t['abbreviation'] for t in teams]

# return league_id for given fantasy_team_id
def get_league(team_id):
    return execute_sql('SELECT league_id FROM fantasy_team WHERE fantasy_team_id = {}'.format(team_id))

# return position of given player
def get_player_position(player_id):
    return execute_sql('SELECT position FROM player WHERE player_id = {}'.format(player_id))

# return lineup_posn_id for given player's position and lineup slot
def get_position_slot(lineup_slot, player):
    player_position = get_player_position(player)[0]['position']
    return execute_sql('SELECT lineup_posn_id FROM lineup_position WHERE abbreviation = "{}" and position = "{}"'.format(lineup_slot, player_position))

# return statstics and their abbreviations from the scoring table
def get_scoring_attributes():
    return execute_sql('SELECT abbreviation, statistic FROM scoring')

# return list of week's matchups with their scores
def get_matchup_scores(week):
    return execute_sql('''SELECT ft1.name as winner, ft2.name as loser, ms.home_team_score, ms.away_team_score
FROM matchup_score ms
  join fantasy_team ft1 on ms.winner = ft1.fantasy_team_id
  join fantasy_team ft2 on ms.loser = ft2.fantasy_team_id
WHERE week = {}'''.format(week))

# loop until a valid integer is inputted and return value
def get_int_input(valid_values, input_text):
    while True:
        try:
            value = int(input('{}: '.format(input_text)))
        except ValueError:
            print('Must enter an integer.')
            continue
        if value not in valid_values:
            print('Invalid value.')
        else:
            break
    return value

# take input for first name, last name, email, and password
# insert new row into user
def add_user():
    first_name = input('First Name: ')
    last_name = input('Last Name: ')
    email = input('Email: ')
    password = input('Password: ')
    sql = 'CALL insert_user("{}", "{}", "{}", "{}")'.format(first_name, last_name, email, password)
    execute_sql(sql)

# take input for league name, commissioner, maximum teams
# insert new row into league
def add_league():
    name = input('League Name: ')
    commissioner = get_int_input(display_users(), 'Commissioner (enter ID)')
    max_teams = int(input('Maximum number of teams: '))
    sql = 'INSERT INTO league (name, commissioner, max_teams) VALUES ("{}", {}, {})'.format(name, commissioner, max_teams)
    execute_sql(sql)

# take input for league, manager, team name, abbreviation
# insert row into fantasy_team
def add_team():
    league = get_int_input(display_leagues(), 'League (enter ID)')
    manager = get_int_input(display_users(), 'Manager (enter ID)')
    name = input('Team Name: ')
    abbreviation = input('Team Abbreviation: ')
    sql = 'CALL add_fantasy_team({}, {}, "{}", "{}")'.format(league, manager, name, abbreviation)
    execute_sql(sql)

# take input for fantasy team and player
# remove player from fantasy team's roster
def drop_player():
    team = get_int_input(display_teams(), 'Team (enter ID)')
    player = get_int_input(display_roster(team), 'Player (enter ID)')
    sql = 'DELETE FROM roster WHERE fantasy_team_id = {} and player_id = {}'.format(team, player)
    execute_sql(sql)

# take input for fantasy team and player
# add player to fantasy team's roster if not full
def add_player():
    team = get_int_input(display_teams(), 'Team (enter ID)')
    league = get_league(team)[0]['league_id']
    player = get_int_input(display_free_agents(league), 'Player (enter ID)')
    sql = 'CALL add_player({}, {})'.format(team, player)
    execute_sql(sql)

# take input for two fantasy teams and two players
# update fantasy_team in roster accordingly
def trade_players():
    team1 = get_int_input(display_teams(), 'Team 1 (enter ID)')
    team2 = get_int_input(display_teams(), 'Team 2 (enter ID)')
    if get_league(team1) == get_league(team2) and team1 != team2:
        player1 = get_int_input(display_roster(team1), 'Player to be traded from Team 1')
        player2 = get_int_input(display_roster(team2), 'Player to be traded from Team 2')
        sql = '''UPDATE roster SET fantasy_team_id = {t2} WHERE fantasy_team_id = {t1} and player_id = {p1};
UPDATE roster SET fantasy_team_id = {t1} WHERE fantasy_team_id = {t2} and player_id = {p2}'''.format(t1=team1, t2=team2, p1=player1, p2=player2)
        execute_sql(sql)
    else:
        print("Must select 2 different teams in the same league.")

# take input for player and new NFL team
# update player's NFL team
def player_team_update():
    player = get_int_input(display_players(), 'Player (enter ID)')
    team_abbreviations = display_nfl_teams()
    while True:
        new_team = input('New Team (enter abbreviation): ')
        if new_team not in team_abbreviations:
            print('Must enter valid team abbreviation.')
        else:
            break
    sql = 'UPDATE player SET nfl_team = "{}" WHERE player_id = {}'.format(new_team, player)
    execute_sql(sql)

# take input for week, team, and all players to be included in weekly lineup according to position slots
# insert rows into lineup
def set_lineup():
    week = get_int_input(list(range(1,18)), 'Week (1-17)')
    team = get_int_input(display_teams(), 'Team (enter ID)')
    curr_lineup = []
    player_ids = display_roster(team)
    for pos in LINEUP:
        while True:
            player = get_int_input(player_ids, '{} (enter ID)'.format(pos))
            position_slot = get_position_slot(pos, player)
            if not position_slot:
                print('Invalid player {} for position slot {}.'.format(player, pos))
            elif player in curr_lineup:
                print('Invalid player {} already in lineup.'.format(player))
            else:
                break
        lineup_posn_id = position_slot[0]['lineup_posn_id']
        sql = 'CALL update_lineup({}, {}, {}, {})'.format(week, team, lineup_posn_id, player)
        execute_sql(sql)
        curr_lineup.append(player)

# take input for week, player, and all possible statistics
# insert rows per statistic into player_performance
def add_statistics():
    week = get_int_input(list(range(1,18)), 'Week (1-17)')
    player = get_int_input(display_players(), 'Player (enter ID)')
    stats = get_scoring_attributes()
    for stat in stats:
        while True:
            try:
                quantity = int(input('{}: '.format(stat['statistic'])))
            except ValueError:
                print('Must enter integer.')
            else:
                break
        sql = 'INSERT INTO player_performance (player_id, week, statistic, quantity) VALUES ({}, {}, "{}", {})'.format(player, week, stat['abbreviation'], quantity)
        execute_sql(sql)

# take input for fantasy team
# output fantasy team's roster
def view_roster():
    team = get_int_input(display_teams(), 'Team (enter ID)')
    display_roster(team)

# take input for league
# output all players not on a roster for the particular league
def view_free_agents():
    league = get_int_input(display_leagues(), 'League (enter ID)')
    display_free_agents(league)

# take input for week
# output scoreboard for each matchup for the particular week
def view_scoreboard():
    week = get_int_input(list(range(1,18)), 'Week (1-17)')
    scoreboard = get_matchup_scores(week)
    template = '{0:20} def. {1:20} {2} - {3}'
    for matchup in scoreboard:
        max_score = max(matchup['home_team_score'], matchup['away_team_score'])
        min_score = min(matchup['home_team_score'], matchup['away_team_score'])
        print(template.format(matchup['winner'], matchup['loser'], max_score, min_score))

# produce a list of non-Quarterbacks with their position, name, and NFL team as well as average, maximum, and minimum scores
# for those with an average greater than 15 and who have always scored more than 10 points
# sort by who's averaged the most points per week, and then the highest maximum
# 3 tables joined, aggregate functions, grouping, 2 ordering fields, 2 HAVING conditions not for joins, non-aggregation function in SELECT, strong motivation
def highest_average_scorers():
    sql = '''SELECT
	p.position as Position,
    CONCAT(p.first_name, " ", p.last_name) as Name,
    p.nfl_team as Team,
    ROUND(AVG(score), 2) as Average,
    MAX(score) as Max,
    MIN(score) as Min
FROM
	player_score ps
    join player p on ps.player_id = p.player_id
    join position pos on p.position = pos.abbreviation
WHERE pos.name <> "Quarterback"
GROUP BY ps.player_id
HAVING Average > 15 and Min > 10
ORDER BY Average DESC, Max DESC'''
    results = execute_sql(sql)
    template = '{0:6}|{1:24}|{2:6}|{3:10}|{4:10}|{5:10}'
    print(template.format('Pos', 'Name', 'Team', 'Average', 'Max', 'Min'))
    for r in results:
        print(template.format(r['Position'], r['Name'], r['Team'], r['Average'], r['Max'], r['Min']))

# produce a list of all players not in a starting lineup for a particular week (Bench players)
# with their position, name, NFL team, and points scored sorted by score and then position
# 3 tables joined, 1 subquery, 2 ordering fields, 2 WHERE conditions not for joins, non-aggregation function in SELECT, strong motivation
def non_starters_scores():
    week = get_int_input(list(range(1,18)), 'Week (1-17)')
    sql = '''SELECT
	p.position as Position,
    CONCAT(p.first_name, " ", p.last_name) as Name,
    p.nfl_team as Team,
    ps.score as Score
FROM
    player_score ps
    join player p on ps.player_id = p.player_id
    join position pos on p.position = pos.abbreviation
WHERE
    ps.week = {w} and
    ps.player_id not in (SELECT player_id FROM lineup l join lineup_position lp on l.position_slot = lp.lineup_posn_id WHERE week = {w} and lp.slot_description not like "Bench%")
ORDER BY Score DESC, FIELD(Position, "QB", "RB", "WR", "TE", "D/ST", "K")'''.format(w=week)
    results = execute_sql(sql)
    template = '{0:6}|{1:24}|{2:6}|{3:10}'
    print(template.format('Pos', 'Name', 'Team', 'Score'))
    for r in results:
        print(template.format(r['Position'], r['Name'], r['Team'], r['Score']))

# find how many players of each possible FLEX position each fantasy team in a particular league has on its roster
# include the team manager, team name, position, and player count, and sort by player count descending and then team name
# 4 tables joined, 1 subquery, aggregate function, grouping, 2 ordering fields, 2 WHERE/HAVING conditions not for joins, non-aggregation function in SELECT, strong motivation
def flex_player_count():
    league = get_int_input(display_leagues(), 'League (enter ID)')
    sql = '''SELECT
    CONCAT(u.first_name, " ", u.last_name) as Manager,
	ft.name as TeamName,
    p.position as Position,
    count(*) as PlayerCount
FROM
	roster r
    join player p on r.player_id = p.player_id
    join fantasy_team ft on r.fantasy_team_id = ft.fantasy_team_id
    join user u on ft.manager = u.user_id
WHERE
	ft.league_id = {l} and
	p.position in (SELECT position FROM lineup_position WHERE abbreviation = "FLEX")
GROUP BY ft.fantasy_team_id, p.position
ORDER BY PlayerCount DESC, TeamName'''.format(l=league)
    results = execute_sql(sql)
    template = '{0:20}|{1:20}|{2:6}|{3:5}'
    print(template.format('Manager', 'Team Name', 'Pos', 'Count'))
    for r in results:
        print(template.format(r['Manager'], r['TeamName'], r['Position'], r['PlayerCount']))

# find which fantasy teams in a particular league have more than 2 players with the same bye week
# including the team manager, the team name, the bye week, and how many players on the fantasy team have that bye week
# sort by bye week and then player count
# 5 tables joined, aggregate function, grouping, 3 ordering fields, 2 WHERE/HAVING conditions not for joins, non-aggregation function in SELECT, strong motivation
def bye_week_player_counts():
    league = get_int_input(display_leagues(), 'League (enter ID)')
    sql = '''SELECT
    CONCAT(u.first_name, " ", u.last_name) as Manager,
	ft.name as TeamName,
    t.bye_week as ByeWeek,
    count(*) as PlayerCount
FROM
	roster r
    join fantasy_team ft on r.fantasy_team_id = ft.fantasy_team_id
    join user u on ft.manager = u.user_id
    join player p on r.player_id = p.player_id
    join nfl_team t on p.nfl_team = t.abbreviation
WHERE
    ft.league_id = {l}
GROUP BY ft.fantasy_team_id, t.bye_week
HAVING PlayerCount > 2
ORDER BY ByeWeek, PlayerCount Desc, TeamName'''.format(l=league)
    results = execute_sql(sql)
    template = '{0:20}|{1:20}|{2:6}|{3:5}'
    print(template.format('Manager', 'Team Name', 'Bye', 'Count'))
    for r in results:
        print(template.format(r['Manager'], r['TeamName'], r['ByeWeek'], r['PlayerCount']))

# view standings for a particular league (manager, team name, wins, losses, points for, points against),
# sort by wins descending, breaking ties with points for
# 3 tables joined, 2 subqueries, aggregate functions, grouping, 2 ordering fields, non-aggregate functions in SELECT, strong motivation
def view_standings():
    league = get_int_input(display_leagues(), 'League (enter ID)')
    sql = '''SELECT
  	CONCAT(u.first_name, " ", u.last_name) as Manager,
	ft.name as TeamName,
    (SELECT count(*) FROM matchup_score WHERE winner = ft.fantasy_team_id) as Wins,
    (SELECT count(*) FROM matchup_score WHERE loser = ft.fantasy_team_id) as Losses,
    SUM(IF (ft.fantasy_team_id = home_team, home_team_score, away_team_score)) as PointsFor,
    SUM(IF (ft.fantasy_team_id = home_team, away_team_score, home_team_score)) as PointsAgainst
FROM
    fantasy_team ft
    join user u on ft.manager = u.user_id
    join matchup_score ms on ft.fantasy_team_id = ms.home_team or ft.fantasy_team_id = ms.away_team
WHERE
    league_id = {l}
GROUP BY ft.fantasy_team_id
ORDER BY Wins DESC, PointsFor DESC'''.format(l=league)
    results = execute_sql(sql)
    template = '{0:20}|{1:20}|{2:5}|{3:5}|{4:8}|{5:8}|'
    print(template.format('Manager', 'Team Name', 'W', 'L', 'PF', 'PA'))
    for r in results:
        print(template.format(r['Manager'], r['TeamName'], r['Wins'], r['Losses'], r['PointsFor'], r['PointsAgainst']))

def main():
    while True:
        print(TASKS)
        try:
            task = int(input('Enter number of task/report to execute or 0 to exit: '))
        except ValueError:
            print('Must enter an integer.')
            continue
        if task == 0:
            break
        elif task == 1:
            add_user()
        elif task == 2:
            add_league()
        elif task == 3:
            add_team()
        elif task == 4:
            drop_player()
        elif task == 5:
            add_player()
        elif task == 6:
            trade_players()
        elif task == 7:
            player_team_update()
        elif task == 8:
            set_lineup()
        elif task == 9:
            add_statistics()
        elif task == 10:
            view_roster()
        elif task == 11:
            view_free_agents()
        elif task == 12:
            view_scoreboard()
        elif task == 13:
            highest_average_scorers()
        elif task == 14:
            non_starters_scores()
        elif task == 15:
            flex_player_count()
        elif task == 16:
            bye_week_player_counts()
        elif task == 17:
            view_standings()
        else:
            print('Invalid value.')
        print('-----------------------------------------------------------------------------')

if __name__ == '__main__':
    main()
