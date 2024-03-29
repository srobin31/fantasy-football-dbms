## CS 3200 Database Design Final Project: Fantasy Football DBMS
### In This Repo
- [ddl.sql](https://github.com/srobin31/fantasy-football-dbms/blob/main/ddl.sql): instantiates the normalized relations in MySQL
- [dml.sql](https://github.com/srobin31/fantasy-football-dbms/blob/main/dml.sql): populates the tables created in ddl.sql
- [3200system.py](https://github.com/srobin31/fantasy-football-dbms/blob/main/3200system.py): executable program that connects to the database created and gives options 
- [stats](https://github.com/srobin31/fantasy-football-dbms/tree/main/stats): folder containing source for all data inserted into player_performance table in dml.sql

### Getting Started
1. First, download and install **[XAMPP v7.4.13](https://www.apachefriends.org/download.html)**. Once installed, run the XAMPP Control Panel, and click the Start button next to MySQL. 
2. Then, start the terminal program (Terminal, Command Prompt, etc.) and navigate to the ``bin`` directory under your XAMPP installation. The default location is ``c:\xampp\mysql\bin`` for Windows and ``/Applications/XAMPP/bin`` for Mac. Once there, execute the following command: ``mysql -u root``, or ``./mysql -u root`` for Mac. At this point you should be brought to a MariaDB prompt. 
3. At this point, you should either clone this repo or download a ZIP of it. If necessary unzip its contents, and save this repo in an easy to type location, such as ``/projects`` (or ``c\projects`` on Windows). 
4. Then go back to the MariaDB prompt and type ``SOURCE path/to/ddl.sql``. This will load the DDL and instantiate tables in a fantasy_football database. Next, load the data into the these tables by executing ``SOURCE path/to/dml.sql``. You now have a fantasy_football database that can be queried.
5. To run the accompanying program to interact with this database, you will need Python 3. If you do not already have it, download any version past 3.7 [here](https://www.python.org/downloads/) and complete its installation. The program uses [PyMySQL](https://pypi.org/project/PyMySQL/), so you will need to install that too which you can do by running ``python3 -m pip install pymysql`` in a new terminal tab or window. 
6. Afterwards, navigate to where you saved the contents of this repo. Run ``python3 3200system.py`` and you should see the command line program running!

### Helpful Videos
- [Annotated Walkthrough](https://youtu.be/qTXBvXdcuJE)
- [System Demo Video](https://youtu.be/LKpBLgWqRVQ)
