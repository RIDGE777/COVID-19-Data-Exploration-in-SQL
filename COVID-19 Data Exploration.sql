--Noticed some data in the location column that was not location data- High income, Low income, Lower middle income, Upper middle income
SELECT DISTINCT(location)
FROM covid_deaths
WHERE location LIKE '%income%'


--Drop this data from the table
--4464 rows deleted
DELETE FROM covid_deaths
WHERE location LIKE '%income%'




SELECT * FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3,4


SELECT * FROM covid_vaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4


--Selecting data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2


--Looking at total_cases Vs total_deaths
--This shows likelihood of dying if you contract COVID-19 in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM covid_deaths
WHERE location = 'Kenya' AND continent IS NOT NULL
ORDER BY 1,2


--Looking at total_cases Vs population
--Shows what percentage of population got infected with COVID-19
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS infected_population_percentage
FROM covid_deaths
WHERE location = 'Kenya' AND continent IS NOT NULL
ORDER BY 1,2


--Looking at countries with highest infection count compared to population
SELECT location, population, MAX(total_cases) as highest_infection_count, 
MAX((total_cases/population) * 100) AS infected_population_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_population_percentage DESC


--Looking at countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC


--BREAKING THE DATA DOWN BY CONTINENT
-- Showing continent with highest case count
SELECT location, MAX(CAST(total_cases AS int)) AS total_case_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_case_count DESC


-- Showing continent with highest death count
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM covid_deaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC


-- GLOBAL NUMBERS
-- To check daily new infections tested
SELECT date, SUM(new_cases)
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- To check daily deaths recorded
SELECT date, SUM(CAST (new_deaths AS int)) 
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- To check daily death percentage vs new cases recorded
SELECT /*date*/ SUM(new_cases) AS new_cases, SUM(CAST (new_deaths AS int)) AS new_deaths, 
SUM( CAST (new_deaths AS int))/ SUM(new_cases) * 100 AS new_death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


-- To check global death percentage as compared to new cases
SELECT SUM(new_cases) AS new_cases, SUM(CAST (new_deaths AS int)) AS new_deaths, 
SUM( CAST (new_deaths AS int))/ SUM(new_cases) * 100 AS new_death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Looking at population vs vaccinations
SELECT * 
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date



-- Checking new_vaccinations vs population
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- To retrieve COVID-19 vaccination data and calculate the rolling sum of new vaccinations for each country.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (CONVERT (bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- Use CTE
With popVsvac (continent, location, date, population, new_vaccination, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM (CONVERT (bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)

SELECT *, (rolling_people_vaccinated/population) * 100 AS rolling_people_vaccinated_percentage
FROM popVsvac



--Using Temp Table
DROP TABLE if exists #rolling_people_vaccinated_percentage
CREATE TABLE #rolling_people_vaccinated_percentage
(
  continent nvarchar(255),
  location nvarchar(255),
  date datetime,
  population numeric,
  new_vaccinations numeric,
  rolling_people_vaccinated numeric
);

INSERT INTO #rolling_people_vaccinated_percentage (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;


SELECT * FROM #rolling_people_vaccinated_percentage


-- Creating View to store data for later visualizations

CREATE VIEW rolling_people_vaccinated_percentage AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
  SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM covid_deaths dea
JOIN covid_vaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



