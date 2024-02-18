-- Question 1. Find all players in the database who played at Vanderbilt University. 
-- Create a list showing each player's first and last names as well as the total salary they earned in the major leagues.
-- Sort this list in descending order by the total salary earned.
-- Which Vanderbilt player earned the most money in the majors?
-- SELECT namefirst, namelast, SUM(salary) AS total_salary
-- FROM people
-- INNER JOIN collegeplaying
-- USING(playerid)
-- INNER JOIN salaries
-- USING(playerid)
-- WHERE schoolid = 'vandy'
-- GROUP BY playerid
-- ORDER BY 3 DESC;


WITH vandy_players AS (
	SELECT DISTINCT playerid
	FROM collegeplaying
	WHERE schoolid = 'vandy'
)
SELECT 
	namefirst || namelast AS fullname, 
	SUM(salary)::int::MONEY AS total_salary
FROM salaries
INNER JOIN vandy_players
USING(playerid)
INNER JOIN people
USING(playerid)
GROUP BY namefirst || namelast
ORDER BY total_salary DESC;
--Answer: David Price

-- Question 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
	ELSE 'Battery'
	END AS position_type,
	SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY 1
--Answer: Battery = 41424, Infield = 58934, Outfield = 29560

-- Question 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the **generate_series** function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)*/
SELECT yearid /10 * 10 AS decade,
	ROUND((SUM(so) * 1.0) / SUM(ghome), 2) AS avg_so,
	ROUND((SUM(hr) * 1.0) / SUM(ghome), 2) AS avg_hr
FROM teams
WHERE yearid >= 1920
GROUP BY 1
ORDER BY 1

-- Question 4.Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.)
-- Consider only players who attempted at least 20 stolen bases.
-- Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
WITH stolen_bases_2016 AS (
SELECT playerID, 
	COALESCE(SUM(SB),0) AS stolen_base, 
	COALESCE(SUM(CS),0) AS caught_stealing, 
	COALESCE(SUM(SB),0) + COALESCE(SUM(CS),0) AS stolen_base_attempts
FROM batting
WHERE yearID = 2016
GROUP BY playerID)

SELECT namefirst, 
	namelast, 
	stolen_base, 
	caught_stealing, 
	stolen_base_attempts, 
	ROUND(stolen_base*1.0/(stolen_base + caught_stealing),3) AS stolen_base_pct
FROM people
LEFT JOIN stolen_bases_2016
USING(playerID)
WHERE stolen_base_attempts >=20
ORDER BY stolen_base_pct DESC;

-- Question 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
SELECT name, w, l
FROM teams
WHERE yearid BETWEEN 1970 and 2016
	And wswin = 'N'
ORDER BY 2 DESC;

SELECT name, w, l
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
	AND wswin = 'Y'
	AND yearid != 1981
ORDER BY 2;

WITH most_team_wins AS (
	SELECT yearid, name, most_wins
	FROM teams
	INNER JOIN(
		SELECT yearid, W AS most_wins
		FROM teams
		GROUP BY yearid)
	USING(yearid)
	WHERE most_wins = W
),

ws_win_team AS (
	SELECT yearid, name, WSwin
	FROM teams
	WHERE WSwin = 'Y'
)
SELECT number_ws_winners_as_most_winners, 
	ROUND(number_ws_winners_as_most_winners*1.0/number_of_distinct_years,3) AS pct_ws_winners_as_most_winners
FROM(
SELECT
	COUNT(DISTINCT(yearid)) AS number_of_distinct_years,
	COUNT(CASE WHEN m.name = w.name THEN 1.0 END) AS number_ws_winners_as_most_winners
FROM most_team_wins AS m
INNER JOIN ws_win_team AS w
USING(yearid)
WHERE yearid BETWEEN 1970 AND 2016)





























-- Question 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- Michael's approach
-- WITH both_league_winners AS (
-- 	SELECT
-- 		playerid
-- 	FROM awardsmanagers
-- 	WHERE awardid = 'TSN Manager of the Year'
-- 		AND lgid IN ('AL', 'NL')
-- 	GROUP BY playerid
-- 	HAVING COUNT(DISTINCT lgid) = 2
-- 	)
-- SELECT
-- 	namefirst || ' ' || namelast AS full_name,
-- 	yearid,
-- 	lgid,
-- 	name AS team_name
-- FROM people
-- INNER JOIN both_league_winners
-- USING(playerid)
-- INNER JOIN awardsmanagers
-- USING(playerid)
-- INNER JOIN managers
-- USING(playerid, yearid, lgid)
-- INNER JOIN teams
-- USING(teamid, yearid,lgid)
-- WHERE awardid = 'TSN Manager of the Year'
-- ORDER BY full_name, yearid;

--My approach
WITH AL_TSN_Managers AS (
SELECT playerid, name AS ALteam_name, yearid, awardsmanagers.lgid
FROM awardsmanagers
INNER JOIN managers
USING(playerid, yearid)
INNER JOIN teams
USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND awardsmanagers.lgid = 'AL'),


NL_TSN_Managers AS (
SELECT playerid, name AS NLteam_name, yearid, awardsmanagers.lgid
FROM awardsmanagers
INNER JOIN managers
USING(playerid, yearid)
INNER JOIN teams
USING(teamid, yearid)
WHERE awardid = 'TSN Manager of the Year'
	AND awardsmanagers.lgid = 'NL')



SELECT namefirst, namelast, ALteam_name, NLteam_name, AL_TSN_Managers.yearid,NL_TSN_Managers.yearid
FROM AL_TSN_Managers
INNER JOIN NL_TSN_Managers
USING(playerid)
INNER JOIN people
USING(playerid);

-- Trey's approach
-- with manager_awards as (
-- 	select 
-- 		p.playerid,
-- 		p.namefirst,
-- 		p.namelast,
-- 		m.teamid,
-- 		aw.yearid,
-- 		aw.lgid
-- 	from people p
-- 	inner join awardsmanagers aw
-- 	using(playerid)
-- 	inner join managers m
-- 	using(playerid)
-- 	where aw.awardid = 'TSN Manager of the Year'
-- ),
-- manager_league_counts as (
-- 	select
-- 		playerid,
-- 		namefirst,
-- 		namelast,
-- 	ARRAY_AGG(distinct teamid) as teams,
-- 	ARRAY_AGG(distinct yearid) as years,
-- 	count(distinct lgid) as lg_count
-- 	from manager_awards
-- 	group by playerid, namefirst, namelast
-- )
-- select playerid, namefirst, namelast, teams, years
-- from manager_league_counts
-- where lg_count = 2

-- Question 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.
WITH pitcherinfo AS(
SELECT playerID, namefirst AS firstname, namelast AS lastname, yearID AS year, SUM(SO) AS strikeouts
FROM pitching
INNER JOIN people
USING(playerID)
WHERE yearID = 2016
GROUP BY playerID, namefirst, namelast, yearID
HAVING SUM(GS) >= 10
),
salaryso AS(
SELECT playerID, firstname, lastname, year, SUM(salary) AS salary, strikeouts
FROM pitcherinfo
INNER JOIN salaries
USING(playerID)
WHERE yearID = 2016
GROUP BY playerID, firstname, lastname, year, strikeouts)

SELECT playerID, firstname, lastname, year, (salary/strikeouts) ::Numeric::MONEY AS dollarsperSo
FROM salaryso
ORDER BY dollarsperSO DESC;
)
-- Question 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.
WITH inducted_hall_of_fame AS (
	SELECT playerid,
		yearid
	FROM halloffame
	WHERE inducted = 'Y'
)

SELECT namefirst, namelast,
	i.yearid AS year_inducted,
	SUM(h) AS career_hits
FROM batting AS b
INNER JOIN people AS p
	ON b.playerid = p.playerid
LEFT JOIN inducted_hall_of_fame AS i
	ON b.playerid = i.playerid
GROUP BY 1, 2, 3, b.playerid
HAVING SUM(h) >= 3000
ORDER BY 1

-- Question 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.
WITH players_1000hits AS(
	SELECT playerid,teamid, SUM(h) AS total_hits
	FROM batting
	GROUP BY playerid, teamid
	HAVING SUM(h) > 1000
)
SELECT playerid, COUNT(teamid) AS team_count, namefirst As firstname, namelast AS lastname
FROM players_1000hits
LEFT JOIN people
USING(playerid)
GROUP BY playerid, firstname, lastname
HAVING COUNT(teamid) > 1
ORDER BY firstname
-- Question 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.
WITH yearly_hr AS (
	SELECT CONCAT(namefirst, ' ', namelast) AS player_name,
		b.playerid,
		b.yearid,
		SUM(hr) AS year_hr, -- players could have played for 2+ teams in the same year
		MAX(SUM(hr)) OVER(PARTITION BY b.playerid) AS max_hr
	FROM batting AS b
	INNER JOIN people AS p
		ON b.playerid = p.playerid
	GROUP BY 1, 2, 3
	ORDER BY 1, 2
),

seasons AS (
	SELECT playerid,
		COUNT(DISTINCT yearid) AS years_played
	FROM batting
	GROUP BY 1
	HAVING COUNT(DISTINCT yearid) >= 10
)

SELECT player_name,
	year_hr,
	years_played
FROM yearly_hr AS y
INNER JOIN seasons AS s
	ON y.playerid = s.playerid
WHERE year_hr = max_hr
	AND yearid = 2016
	AND year_hr > 0;
