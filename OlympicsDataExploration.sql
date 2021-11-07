select * from OLYMPICS_HISTORY;
select * from OLYMPICS_HISTORY_NOC_REGIONS;

-- How many olympics games have been held?
Select COUNT(Distinct Games) as TotalOlympicGames_Held
from OLYMPICS_HISTORY;

-- List down all Olympics games held so far.
Select Distinct year,Games,city
from OLYMPICS_HISTORY;


--Mention the total no of nations who participated in each olympics game?
Select  games,Count(Distinct NOC) as 'Total No of Nations'
from OLYMPICS_HISTORY
GROUP BY Games;


-- Which year saw the highest and lowest no of countries participating in olympics?
select Distinct FIRST_VALUE(games) over (order by TotalNations) as Lowest_Countries,
 FIRST_VALUE(games) over (order by TotalNations desc) as Highest_Countries
from (
		Select  games,Count(Distinct NOC) as 'TotalNations'
from OLYMPICS_HISTORY
GROUP BY Games) x


-- Which nation has participated in all of the olympic games?
with tot_games as 
(Select count(Distinct games) as total_games from OLYMPICS_HISTORY),
countries as 
(Select games,olnoc.region as country from OLYMPICS_HISTORY olh join OLYMPICS_HISTORY_NOC_REGIONS olnoc on olh.NOC = olnoc.NOC),
countries_partcipated as
(select country,COUNT(Distinct games) as total_partcipated_countries from countries group by country)
Select cp.*
from countries_partcipated cp
join tot_games tg 
on tg.total_games = cp.total_partcipated_countries


select * from OLYMPICS_HISTORY;
select * from OLYMPICS_HISTORY_NOC_REGIONS;



-- Identify the sport which was played in all summer olympics.
with t1 as 
(select Count(Distinct games) as totalSummerGames
from OLYMPICS_HISTORY
where season = 'Summer'),
t2 as 
(Select sport,games
from OLYMPICS_HISTORY
where season = 'Summer'),
t3 as 
(select sport,Count(Distinct games) as no_of_games 
from t2
group by sport)
select * 
from t3
join t1 
on t3.no_of_games = t1.totalSummerGames;

-- Which Sports were just played only once in the olympics?
select *
from 
(select sport,Count(Distinct games) as no_of_games
from OLYMPICS_HISTORY
group by Sport) x
where x.no_of_games = 1


-- Fetch the total no of sports played in each olympic games.
Select games,Count(Distinct Sport) as no_of_games
from OLYMPICS_HISTORY
Group by Games
order by no_of_games desc;

Select * from OLYMPICS_HISTORY;


-- Fetch oldest athletes to win a gold medal
with t1 as
(select * from OLYMPICS_HISTORY where Medal = 'Gold' and Age !='NA'),
t2 as 
(select *,rank() over (order by Age desc) as Age_Rank from t1)
Select *
from t2
where Age_Rank = 1

--Fetch the top 5 athletes who have won the most gold medals.
with t1 as 
(Select name,team,Medal from OLYMPICS_HISTORY where Medal = 'Gold'),
t2 as 
(Select name,Count(Medal) as Most_gold_medals from t1 Group By name)
Select Distinct top 5 t2.name,t1.team,t2.Most_gold_medals
from t2
join t1
on t1.name = t2.name
order by t2.Most_gold_medals desc


-- Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as 
(Select name,team,Medal from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as 
(Select name,Count(Medal) as No_of_medals from t1 Group By name)
Select Distinct top 5 t2.name,t1.team,t2.No_of_medals
from t2
join t1
on t1.name = t2.name
order by t2.No_of_medals desc


-- Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as 
(Select olnoc.region as Country,olh.Medal from OLYMPICS_HISTORY olh join OLYMPICS_HISTORY_NOC_REGIONS olnoc on olh.NOC = olnoc.NOC where Medal != 'NA'),
t2 as 
(Select Country,Count(Medal) as No_of_medals from t1 Group By Country)
Select Distinct top 5 t2.Country,t2.No_of_medals
from t2
join t1
on t1.Country = t2.Country
order by t2.No_of_medals desc


-- List down total gold, silver and bronze medals won by each country.
with t1 as
(select * from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as 
(select * from OLYMPICS_HISTORY_NOC_REGIONS),
t3 as 
(select t2.region as Country, t1.Medal from t1 join t2 on t1.NOC = t2.NOC),
t4 as 
(select Country,Medal,Count(1) as Total_Medals from t3 Group by Country,Medal)
Select * 
from t4 
PIVOT
(
	SUM(Total_Medals)
	FOR Medal
	IN (Gold,Silver,Bronze)
) Pivottable
order by Pivottable.Gold desc;


-- List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
with t1 as
(select * from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as 
(select * from OLYMPICS_HISTORY_NOC_REGIONS),
t3 as 
(select t1.games as Games,t2.region as Country, t1.Medal as Medal from t1 join t2 on t1.NOC = t2.NOC),
t4 as 
(select Games,Country,Medal,Count(1) as Total_Medals from t3 Group by Games,Country,Medal)
Select * 
from t4 
PIVOT
(
	SUM(Total_Medals)
	FOR Medal
	IN (Gold,Silver,Bronze)
) Pivottable
order by Games;


-- Identify which country won the most gold, most silver and most bronze medals in each olympic games.
with t1 as 
(select * from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as
(select * from OLYMPICS_HISTORY_NOC_REGIONS),
t3 as 
(select t1.Games as Games,t2.region as Country,t1.Medal as Medals from t1 join t2 on t1.NOC = t2.NOC),
t4 as 
(select Games,Country,Medals,Sum(1) as Total_Medals from t3 Group by Games,Country,Medals)
Select Distinct Games,Max_Gold,Max_Silver,Max_Bronze
from 
(Select *,concat(FIRST_VALUE(Country) over (partition by Games order by Gold desc),'-',FIRST_VALUE(Gold) over (partition by Games order by Gold desc)) as Max_Gold,
concat(FIRST_VALUE(Country) over (partition by Games order by Silver desc),'-',FIRST_VALUE(Silver) over (partition by Games order by Silver desc)) as Max_Silver,
concat(FIRST_VALUE(Country) over (partition by Games order by Bronze desc),'-',FIRST_VALUE(Bronze) over (partition by Games order by Bronze desc)) as Max_Bronze
from t4 
PIVOT
(
	SUM(Total_Medals)
	FOR Medals
	IN (Gold,Silver,Bronze)
) Pivottable)x

--  Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
with t1 as 
(select * from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as
(select * from OLYMPICS_HISTORY_NOC_REGIONS),
t3 as 
(select t1.Games as Games,t2.region as Country,t1.Medal as Medals from t1 join t2 on t1.NOC = t2.NOC),
t4 as 
(select Games,Country,Medals,Sum(1) as Each_Medal from t3 Group by Games,Country,Medals),
t5 as 
(select Games,Country,Sum(Each_Medal) AS All_Medals from t4 Group by Games,Country),
t6 as 
(Select t5.Games,t5.Country,t5.All_Medals,t4.Each_Medal,t4.Medals from t5  join t4  on t4.Games = t5.Games and t4.Country = t5.Country),
t7 as 
(select *,concat(FIRST_VALUE(Country) over (partition by Games order by Gold desc),'-',FIRST_VALUE(Gold) over (partition by Games order by Gold desc)) as Max_Gold,
concat(FIRST_VALUE(Country) over (partition by Games order by Silver desc),'-',FIRST_VALUE(Silver) over (partition by Games order by Silver desc)) as Max_Silver,
concat(FIRST_VALUE(Country) over (partition by Games order by Bronze desc),'-',FIRST_VALUE(Bronze) over (partition by Games order by Bronze desc)) as Max_Bronze,
concat(FIRST_VALUE(Country) over (partition by games order by All_Medals desc),'-',FIRST_VALUE(All_Medals) over (partition by games order by All_Medals desc)) as Max_Medals
from t6 
PIVOT
(
	SUM(Each_Medal)
	FOR Medals
	IN (Gold,Silver,Bronze)
) Pivottable)
Select distinct Games,Max_Gold,Max_Silver,Max_Bronze,Max_Medals
from t7
order by Games


-- Which countries have never won gold medal but have won silver/bronze medals?
with t1 as
(select * from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as
(select * from OLYMPICS_HISTORY_NOC_REGIONS),
t3 as 
(select olnoc.region as Country,ol.Medal,count(1) as Tot_medals from t1 ol join t2 olnoc on ol.NOC = olnoc.NOC group by olnoc.region,ol.Medal)
Select * 
from 
(select Distinct Country,coalesce(Gold,0) as Gold,coalesce(Silver,0) as Silver,coalesce(Bronze,0) as Bronze 
from t3
PIVOT
(
	SUM(Tot_medals)
	FOR Medal
	IN (Gold,Silver,Bronze)
) Pivottable) x
where x.Gold = 0 and (x.Silver > 0 or x.Bronze > 0)
order by Bronze desc 


-- In which Sport/event, India has won highest medals.
with t1 as
(select * from OLYMPICS_HISTORY where Medal != 'NA'),
t2 as
(select * from OLYMPICS_HISTORY_NOC_REGIONS),
t3 as 
(select olnoc.region as Country,ol.Medal,ol.Sport,count(1) as Tot_medals from t1 ol join t2 olnoc on ol.NOC = olnoc.NOC group by olnoc.region,ol.Sport,ol.Medal)
Select  top 1 Country,Sport,Sum(Tot_medals) as Max_Medals
from t3
where Country = 'India'
group by Country,Sport
order by Max_Medals desc;