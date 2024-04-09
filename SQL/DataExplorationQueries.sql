USE [Portafolio-Covid]

/* Total de casos vs Total de muertes*/

SELECT [location], [date], [total_cases], [total_deaths], 
      CAST([total_deaths] AS float) / CAST([total_cases] AS float) *100 AS Deathpercentage
FROM [dbo].[covid-data-deaths]
ORDER BY 1, 2;

/*Probabilidad de morir si nos contagiamos de COVID en Ecuador*/

SELECT [location], [date], [total_cases], [total_deaths], 
      CAST([total_deaths] AS float) / CAST([total_cases] AS float) *100 AS Deathpercentage
FROM [dbo].[covid-data-deaths]
WHERE location LIKE '%Ecuador%'
AND [continent] IS NOT NULL
ORDER BY 1, 2;

/*Total de casos vs la Población, aquí se muestra que porcentaje de población tiene COVID*/

SELECT [location], [date], [population],[total_cases], 
      CAST([total_cases] AS float) / CAST( [population]AS float) *100 AS PercentPopulationInfected
FROM [dbo].[covid-data-deaths]
ORDER BY 1, 2;

/*Países con tasas de infección mas alta en comparación con la población*/

SELECT [location], [population], MAX([total_cases]) AS HighestInfectionCount, 
      MAX(CAST([total_cases] AS float)) / CAST([population] AS float) * 100 AS PercentPopulationInfected
FROM [dbo].[covid-data-deaths]
GROUP BY [location], [population]
ORDER BY PercentPopulationInfected DESC

/*Países con mayor número de muertes por población*/

SELECT [location], MAX(CAST([total_deaths] AS Int)) AS TotalDeathCount
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

/* Continentes con mayor número de muertos por población */

SELECT [continent], MAX(CAST([total_deaths] AS Int)) AS TotalDeathCount
FROM [dbo].[covid-data-deaths]
where [continent] IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

/*Números globales*/

--Si queremos filtrar por fecha el numero de casos

SELECT [date], SUM([new_cases]) AS [total_cases],SUM(CAST([new_deaths] AS INT)) AS [total_deaths],
      CASE WHEN SUM([new_cases]) > 0 THEN (SUM(CAST([new_deaths] AS INT)) / NULLIF(SUM([new_cases]), 0)) * 100 
      ELSE NULL END AS DeathPercentage
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
GROUP BY [date]
ORDER BY 1, 2;

/* Verificamos por el numero total de casos en el mundo */  

SELECT SUM([new_cases]) AS [total_cases], SUM(CAST([new_deaths] AS INT)) AS [total_deaths], 
	   SUM(CAST([new_deaths] AS INT)) /SUM([new_cases]) *100 AS DeathPercentage
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
ORDER BY 1, 2;

/*Población total vs Vacunación*/

SELECT dea.[continent], dea.[location], dea.[date], dea.[population], vac.[new_vaccinations],
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.[location] ORDER BY dea.[location], dea.[Date])
AS RollingPeopleVaccinated
FROM [dbo].[covid-data-deaths] dea
JOIN [dbo].[covid-data-vaccinations] vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date] 
WHERE dea.[continent] IS NOT NULL
ORDER BY 2, 3

/* Uso de CTE para realizar el cálculo de la partición por en la consulta anterior */

WITH PopvsVac ([Continent], [Location], [Date], [Population], [new_vaccinations], RollingPeopleVaccinated)
AS
(SELECT dea.[continent], dea.[location], dea.[date], dea.[population], vac.[new_vaccinations],
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.[location] ORDER BY dea.[location], dea.[Date])
AS RollingPeopleVaccinated
FROM [dbo].[covid-data-deaths] dea
JOIN [dbo].[covid-data-vaccinations] vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date] 
WHERE dea.[continent] IS NOT NULL)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac

/* Uso de la tabla temporal para realizar el cálculo de la partición en la consulta anterior */

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
[Continent] NVARCHAR(255),
[Location] nvarchar(255),
[Date] datetime,
[Population] numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated 
SELECT dea.[continent], dea.[location], dea.[date], dea.[population], vac.[new_vaccinations],
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.[location] ORDER BY dea.[location], dea.[Date])
AS RollingPeopleVaccinated
FROM [dbo].[covid-data-deaths] dea
JOIN [dbo].[covid-data-vaccinations] vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date] 

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

/*  Creación de vista para almacenar datos para visualizaciones posteriores. */

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.[continent], dea.[location], dea.[date], dea.[population], vac.[new_vaccinations],
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.[location] ORDER BY dea.[location], dea.[Date])
AS RollingPeopleVaccinated
FROM [dbo].[covid-data-deaths] dea
JOIN [dbo].[covid-data-vaccinations] vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date]
WHERE [dea].[continent] IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated