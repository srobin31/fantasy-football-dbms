players = {}

with open('players.csv') as players_file:
    for row in players_file:
        row = row.strip().split(',')
        players[row[0]] = {'name': row[1], 'pos': row[2], 'team': row[3]}

def print_values(id, week, stat, quantity):
    print("({id}, {week}, '{stat}', {num}),".format(id=id, week=week, stat=stat, num=quantity))

def get_qb_stats(player_id, week, stats):
    _, _, _, py, ptd, _, ry, rtd, ints, fum = stats
    print_values(player_id, week, 'PY', py)
    print_values(player_id, week, 'PTD', ptd)
    print_values(player_id, week, 'RY', ry)
    print_values(player_id, week, 'RTD', rtd)
    print_values(player_id, week, 'TO', int(ints) + int(fum))

def get_rb_stats(player_id, week, stats):
    _, _, ry, rtd, _, rec, rey, retd, ints, fum = stats
    print_values(player_id, week, 'RY', ry)
    print_values(player_id, week, 'RTD', rtd)
    print_values(player_id, week, 'REC', rec)
    print_values(player_id, week, 'REY', rey)
    print_values(player_id, week, 'RETD', retd)
    print_values(player_id, week, 'TO', int(ints) + int(fum))

def get_wr_stats(player_id, week, stats):
    _, _, rec, rey, retd, _, ry, rtd, ints, fum = stats
    print_values(player_id, week, 'RY', ry)
    print_values(player_id, week, 'RTD', rtd)
    print_values(player_id, week, 'REC', rec)
    print_values(player_id, week, 'REY', rey)
    print_values(player_id, week, 'RETD', retd)
    print_values(player_id, week, 'TO', int(ints) + int(fum))

def get_dst_stats(player_id, week, stats):
    sacks, fum, ints, tds, safeties, ya, pa = stats
    print_values(player_id, week, 'SK', sacks)
    print_values(player_id, week, 'TOC', int(fum) + int(ints))
    print_values(player_id, week, 'DTD', tds)
    print_values(player_id, week, 'SF', safeties)
    print_values(player_id, week, 'YA', ya)
    print_values(player_id, week, 'PA', pa)

def get_k_stats(player_id, week, stats):
    fga, fgm, xpa, xpm = stats
    print_values(player_id, week, 'MFG', int(fga) - int(fgm))
    print_values(player_id, week, 'FG', fgm)
    print_values(player_id, week, 'PAT', xpm)

POSITIONS = ['QB', 'RB', 'WR', 'TE', 'DST', 'K']
for week in ["1", "2"]:
    for pos in POSITIONS:
        with open('week{}/{}.txt'.format(week, pos)) as stats:
            for row in stats:
                row = row.strip().split('\t')
                if pos == 'DST':
                    player = {'name': row[0] + " D/ST", 'pos': "D/ST", 'team': row[1]}
                else:
                    player = {'name': row[0], 'pos': pos, 'team': row[1]}

                if player in players.values():
                    player_id = list(players.keys())[list(players.values()).index(player)]

                    stats = []
                    for stat in row[3:]:
                        if stat == '–':
                            stat = '0'
                        stats.append(stat)

                    if pos == 'QB':
                        get_qb_stats(player_id, week, stats)
                    elif pos == 'RB':
                        get_rb_stats(player_id, week, stats)
                    elif pos in ['WR', 'TE']:
                        get_wr_stats(player_id, week, stats)
                    elif pos == 'DST':
                        get_dst_stats(player_id, week, stats)
                    elif pos == 'K':
                        get_k_stats(player_id, week, stats)
