# fantasy-football-dbms
## CS 3200 Database Design Final Project
## Fantasy Football DBMS
A group of friends has approached me about moving their fantasy football league to a DBMS for the purposes of potentially starting a new fantasy football platform as well as easier consumption and analysis of football players’ stats and fantasy team data.

### 1.1 Users
Anyone who wants to have a fantasy team on this platform or be a league commissioner must be registered as a user, proving their first and last name, an email address, and password.

### 1.2 League
Each new football season means a new fantasy league. For some users, it might even mean multiple new leagues. Each league has a name, a commissioner, the number of teams, and a bunch of league settings.

### 1.3 Teams
Within a league is a set of teams, each managed by a user. A team belongs to a league and has a name, abbreviation, and manager.

### 1.4 Players
As fantasy football is based on the actual production of real athletes, a table is needed containing every player that can be drafted to a fantasy team. Each player has a name, a position, an NFL team.

### 1.5 Roster
A table is needed to keep track of which players are owned by which fantasy teams. A player can only be owned by one fantasy team per league, and teams can own at most 17 players.

### 1.6 Weekly Lineup
Each week, before a batch of football games are played, league members need to set their lineup, picking which of their rostered players will count towards earning them points. A weekly lineup should exist for each fantasy team and week, consisting of all the players selected for the lineup according to position slots. Any player selected for a lineup must be on the particular fantasy team's roster and cannot be in any particular week's lineup more than once.

### 1.7 Matchup
Each week, fantasy league teams will be paired up and go head-to-head with another team in the same league. Each team's score will be determined by looking at whose lineup scored more points for a given week according to the league's scoring settings. This is based on the summation of individual player performances for the week.

### 1.8 Player Performance
Each week, as players play NFL games, their stats are recorded regardless of position. 
