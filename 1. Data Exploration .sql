SELECT *
FROM PortfolioProject.dbo.CovidDeaths
ORDER BY 3,4

/*
SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3,4
*/

-- Selecting data 

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Likelihood of dying if infected by covid in a speciefic country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathToCaseRatio
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 2 DESC,1 


-- Total Cases vs Population
-- What percentage of population by covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 as CaseToPopulationRatio
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%turkmenistan%'
ORDER BY 2 DESC,1 

-- Looking at highest infection rate compared to population
SELECT Location, MAX(total_cases) as TotalCases, MAX(population), population, (MAX(total_cases)/MAX(population))*100 as CaseToPopulationRatio
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%turkmenistan%'
GROUP BY Location, Population
ORDER BY 5 DESC



--LET'S Break data by Contitents

-- Looking at highest death rate compared to population

SELECT Continent, MAX(total_deaths) as TotalDeathes, MAX(population), (MAX(total_deaths)/MAX(population))*100 as DeathsToPopulationRatio
FROM PortfolioProject..CovidDeaths
WHERE Continent is not NULL
GROUP BY Continent
ORDER BY 4 DESC


-- Breaking Globally

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN New_cases FLOAT

ALTER TABLE PortfolioProject..CovidDeaths
ALTER COLUMN New_deaths FLOAT

DROP TABLE #Temp_DailyDeathToCase
CREATE TABLE #Temp_DailyDeathToCase
(
    Date date,
    TotalCases FLOAT,
    TotalDeaths FLOAT,
)

INSERT INTO #Temp_DailyDeathToCase
SELECT Date, SUM(new_cases) as TotalCases, SUM(New_deaths) as TotalDeaths /*SUM(Cast(New_deaths as int))/SUM(new_cases)*100
 as DeathPercentage 
CASE 
WHEN SUM(new_cases) < SUM(New_deaths) then SUM(New_deaths)/(SUM(New_deaths)-SUM(new_cases))*100
WHEN SUM(new_deaths) = 0 THEN 0
ELSE SUM(New_deaths)/SUM(new_cases)*100
END as DeathPercentage */
FROM portfolioProject..CovidDeaths
WHERE Continent is not NULL 
GROUP BY date
ORDER BY 1

SELECT *
FROM #Temp_DailyDeathToCase
ORDER BY 1

SELECT #Temp_DailyDeathToCase.Date, #Temp_DailyDeathToCase.TotalCases, #Temp_DailyDeathToCase.TotalDeaths, 
CASE
WHEN #Temp_DailyDeathToCase.TotalCases = 0 THEN #Temp_DailyDeathToCase.TotalDeaths/1 * 100
WHEN #Temp_DailyDeathToCase.TotalDeaths is NULL and #Temp_DailyDeathToCase.TotalCases is null THEN NULL
WHEN #Temp_DailyDeathToCase.TotalDeaths NOT IN (NULL,0) and #Temp_DailyDeathToCase.TotalCases NOT IN (NULL,0) THEN #Temp_DailyDeathToCase.TotalDeaths / #Temp_DailyDeathToCase.TotalCases * 100
ELSE cast(#Temp_DailyDeathToCase.TotalDeaths / #Temp_DailyDeathToCase.TotalCases as FLOAT) * 100
END as DeathToCaseRatio
FROM #Temp_DailyDeathToCase
ORDER BY 4 DESC


SELECT SUM(new_cases) as TotalCases, SUM(New_deaths) as TotalDeaths, SUM(Cast(New_deaths as int))/SUM(new_cases)*100
 as DeathPercentage 
/*CASE 
WHEN SUM(new_cases) < SUM(New_deaths) then SUM(New_deaths)/(SUM(New_deaths)-SUM(new_cases))*100
WHEN SUM(new_deaths) = 0 THEN 0
ELSE SUM(New_deaths)/SUM(new_cases)*100
END as DeathPercentage */
FROM portfolioProject..CovidDeaths
WHERE Continent is not NULL 
ORDER BY 1


SELECT *
FROM PortfolioProject..CovidVaccinations


-- Total Vaccination vs Population

-- CTE way

With VacvsPop (continent, Location, date, population, new_vaccinations,RollingVaccinated)
as
(
SELECT dea.continent, dea.LOCATION, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON  dea.Location = vac.Location
and dea.date = vac.date
WHERE dea.continent is NOT NULL and new_vaccinations <> 0
)
SELECT *, (RollingVaccinated/population)*100 as VacvsPop
FROM VacvsPop


-- TempTable way

DROP TABLE IF EXISTS #temp_VacvsPop 
Create Table #temp_VacvsPop 
(continent NVARCHAR(255), 
Location NVARCHAR(255),
date DATETIME, 
population NUMERIC,
new_vaccinations NUMERIC,
RollingVaccinated NUMERIC)

INSERT INTO #temp_VacvsPop
SELECT dea.continent, dea.LOCATION, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON  dea.Location = vac.Location
and dea.date = vac.date
WHERE dea.continent is NOT NULL --and new_vaccinations <> 0

SELECT *, (RollingVaccinated/population)*100 as temp_VacvsPop
FROM #temp_VacvsPop



-- Creating View to store data for future visuals


CREATE VIEW VacvsPopPercent AS
SELECT dea.continent, dea.LOCATION, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) over (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON  dea.Location = vac.Location
and dea.date = vac.date
WHERE dea.continent is NOT NULL --and new_vaccinations <> 0

SELECT *
FROM VacvsPopPercent