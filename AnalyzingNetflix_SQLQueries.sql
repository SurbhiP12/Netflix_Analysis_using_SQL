CREATE 
	Database Netflix_Project;
    

USE 
	Netflix_Project;

CREATE 
	Table Netflix_data (
	Title TEXT
,	Genre TEXT
,	Tags TEXT
,	Languages TEXT
,	`Series or Movie` CHAR(50)
,	`Hidden Gem Score` DECIMAL(2,1)
,	`Country Availability` TEXT
,	Runtime CHAR(100)
,	Director TEXT
,	Writer TEXT
,	Actors TEXT
,	`View Rating` VARCHAR(100)
,	`IMDb Score` DECIMAL(2,1)
,	`Rotten Tomatoes Score` INT
,	`Metacritic Score` INT
,	`Awards Received` INT
,	`Awards Nominated For` LONG
,	Boxoffice_$ INT
,	`Release Date` CHAR(50)
,	`Netflix Release Date` CHAR(50)
,	`Production House` TEXT
,	`Netflix Link` TEXT
,	`IMDb Link` TEXT
,	Summary TEXT
,	`IMDb Votes` INT
	);

DESCRIBE 
	Netflix_data;

SELECT *
	From Netflix_data;
    SET sql_mode="";
load data local infile
"D:\\sp-data_analytics\\excel\\Netflix_Dataset.csv"
into table Netflix_data
fields terminated by ','
enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows;
ALTER 
	Table Netflix_data
ADD 
	Column Release_Date DATE,
ADD 
	Column Netflix_Release_Date DATE;

SET 
	SQL_SAFE_UPDATES = 0;

UPDATE 
	Netflix_data
SET 
	Release_Date = str_to_date(`Release Date`, "%d-%M-%y"),
	Netflix_Release_Date = str_to_date(`Netflix Release Date`, "%d-%m-%Y");

ALTER 
	Table Netflix_data
DROP 
	Column `Release Date`,
DROP 
	Column `Netflix Release Date`;

Select * from Netflix_data;
/* 1. Which among the 2 categories (Series vs. Movie) is more present in the Netflix product catalog? */

ALTER 
	Table Netflix_data
CHANGE `Series or Movie` Category CHAR(50); 	/* Changed the Column name for convinience */
-------------
SELECT 
	Category
,	count(*) as Quantity
	FROM 
		Netflix_data
	GROUP BY 
		Category;

/* 2. Which are the top 3 genres which are mostly requested by the viewers or most popular within two categories? */

CREATE 
	View Step1 as 
SELECT 
	Category
,	Genre 
,	count(*) as Quantity
,	RANK() over (Partition By Category 
					Order By Count(*) DESC) as Topn_Genre 
	FROM 
		Netflix_data
	WHERE
		Genre <> "" 	/*Ignoring the blank records*/
	GROUP BY 
		Genre;

SELECT *
	FROM 
		Step1 as s1
	WHERE
		Topn_Genre IN (1,2,3);

/* 3. Which are the hidden gems under the two main categories? 
	--> Hidden gems score indicates the films with fewer reviews but with very high ratings */
    
SELECT * 
	FROM (
		SELECT 
			Category
		,	Title
		,	`Hidden Gem Score`
		,	RANK() over (Partition by Category 
						  Order By `Hidden Gem Score` DESC) as TopNRank_HiddenGem
			FROM 
				Netflix_data
		 ) as tt
    WHERE 
		TopNRank_HiddenGem between 1 AND 10;

/* 4. Which are the top rated Series and Movies based on IMDB score? */

/*TOP 10 Movies*/
SELECT 
	Category
,	Title
,	`IMDB Score`
	FROM
		Netflix_data
	WHERE 
		Category = "Movie"
	ORDER BY
		`IMDB Score` DESC
	,	Title
        LIMIT 10;
---------------------
/*TOP 10 Series*/
SELECT 
	Category
,	Title
,	`IMDB Score`
	FROM
		Netflix_data
	WHERE 
		Category = "Series"
	ORDER BY 
		`IMDB Score` DESC
	,	Title
        LIMIT 10;

/* 5. How the Rotten tomatoes score & Metacritic score is varying for each Series/Movies? What is the combined score? */

/*For Series*/
SELECT
	Category
,	Title
,	IF(`Rotten Tomatoes Score` > 0 
		,	`Rotten Tomatoes Score`
		,		"Null") as `Rotten Tomatoes Score`
,	IF(`Metacritic Score`> 0 
		,	`Metacritic Score` 
		,		"Null") as `Metacritic Score`
,	(`Rotten Tomatoes Score` + `Metacritic Score`) as Comb_Score
	FROM
		Netflix_data
	WHERE
		Category = "Series"
		AND `Rotten Tomatoes Score` <> "Null" 
		AND `Metacritic Score` <> "Null"
	ORDER BY
		Comb_Score DESC;
----------------
/*For Movies*/
SELECT
	Category
,	Title
,	IF(`Rotten Tomatoes Score` > 0 
		,	`Rotten Tomatoes Score`
		,		"Null") as `Rotten Tomatoes Score`
,	IF(`Metacritic Score`> 0 
		,	`Metacritic Score` 
		,		"Null") as `Metacritic Score`
,	(`Rotten Tomatoes Score` + `Metacritic Score`) as Comb_Score
	FROM
		Netflix_data
	WHERE
		Category = "Movie"
		AND `Rotten Tomatoes Score` <> "Null" 
		AND `Metacritic Score` <> "Null"
	ORDER BY
		Comb_Score DESC;

/* 6. Does Rotten tomatoes score affect the box office return? Does higher Rotten Tomatoes Score imply higher box office collection? */

SELECT
	`Rotten Tomatoes Score`
,	ROUND(AVG(Boxoffice_$)) as Avg_BOCollection_$
	FROM
		Netflix_data
	GROUP BY 
		`Rotten Tomatoes Score`
    ORDER BY 
		Avg_BOCollection_$ DESC;
-------------------
SELECT
	ROUND(AVG(IF(`Rotten Tomatoes Score` > 80
				  ,	 Boxoffice_$, 0))) as High_RTScore 	/*Considered Score > 80 as High RT Score*/
,	ROUND(AVG(IF(`Rotten Tomatoes Score` < 80
				  ,	  Boxoffice_$, 0))) as Low_RTScore
	FROM
		Netflix_data;

/* 7. Which movies/series has received the most number of awards? */

SELECT 
	Category
,	Title
,	`Awards Received`
	FROM (
		SELECT
			Category
		,	Title
		,	`Awards Received`
		,	Row_number() over (Partition by Category 
								Order by `Awards Received` DESC, Title ASC) as TopNRank_Awards
			FROM
				Netflix_data) as tt
	WHERE 
		TopNRank_Awards between 1 AND 10;
		
/* 8. What is the Year-wise and Month-wise Total Box-office Collection for the FY 2020-21? */

SELECT
	YEAR(Release_date) as Year_name
,	IFNULL(MONTHNAME(Release_Date), "YearTotal") as Month_name
,	SUM(Boxoffice_$) as TotalCollection
	FROM
		Netflix_data
	WHERE 
		Release_date between '2020-04-01' AND '2021-03-31'
	GROUP BY
		YEAR(Release_date)
	,	MONTHNAME(Release_Date) WITH ROLLUP
	ORDER BY
		YEAR(Release_date);

/* 9. What is the Productivity per year on Netflix? */

/*For Movies*/
SELECT
	YEAR(Netflix_Release_date) as Release_Year
,	COUNT(Title) as No_of_Release
	FROM
		Netflix_data
	WHERE
		Category = "Movie"
	GROUP BY
		YEAR(Netflix_Release_Date);
-----------------
/*For Series*/
SELECT
	YEAR(Netflix_Release_date) as Release_Year
,	COUNT(Title) as No_of_Release
	FROM
		Netflix_data
	WHERE
		Category = "Series"
	GROUP BY
		YEAR(Netflix_Release_Date);
    
/* 10. How many Movies & Series are there based on different View Rating? */

SELECT
	`View Rating`
,	Count(*) as Quantity
	FROM
		Netflix_data
	WHERE
		`View Rating` <> ""
	GROUP BY
		`View Rating`;

/* 11. List the latest (2021) Korean Movies & Series sorted by month of release. */

SELECT
	Category
,	Title
,	MONTHNAME(Netflix_Release_Date) as ReleaseMonth_2021
	FROM
		Netflix_data
	WHERE
		YEAR(Netflix_Release_Date) = 2021
        AND Languages LIKE "Korean"
	ORDER BY 
		Category
	,	MONTH(Netflix_Release_Date) DESC;
    
/* 12. Which Top 5 movies/series has received highest IMDB Rating sorted by IMDB Votes count Descending? */

/*Top 5 Movies*/
SELECT
	Title
,	`IMDB Score`
,	`IMDB Votes`
	FROM
		Netflix_data
	WHERE
		Category = "Movie"
	ORDER BY
		`IMDB Votes` DESC
        LIMIT 5;
----------------
/*Top 5 Series*/
SELECT
	Title
,	`IMDB Score`
,	`IMDB Votes`
	FROM
		Netflix_data
	WHERE
		Category = "Series"
	ORDER BY
		`IMDB Votes` DESC
        LIMIT 5;
        
/* 13. Is there any correlation between IMDB Votes and BOX Office? */

SELECT
	`IMDB Votes`
,	Boxoffice_$
	FROM
		Netflix_data
	WHERE
		`IMDB Votes` <> 0
        AND Boxoffice_$ != 0
	ORDER BY
		Boxoffice_$ DESC;
    
