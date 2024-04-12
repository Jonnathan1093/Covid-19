# COVID-19
Este repositorio incluye datasets con los eventos registrados del COVID-19 desde 10 de Enero del 2020, hasta el 24 de Marzo del 2024.

**La información lo pueden encontrar en la siguiente dirección:**
- https://ourworldindata.org/covid-deaths


![Data](https://github.com/Jonnathan1093/Covid-19/assets/90915190/eaec4dcf-c90c-444a-84ce-29708db03f12)

# SQL QUERIES:
Total de casos vs Total de muertes.

``` sql

SELECT [location], [date], [total_cases], [total_deaths], 
      CAST([total_deaths] AS float) / CAST([total_cases] AS float) *100 AS Deathpercentage
FROM [dbo].[covid-data-deaths]
ORDER BY 1, 2;
```
Probabilidad de morir si nos contagiamos de COVID en Ecuador.

```sql
SELECT [location], [date], [total_cases], [total_deaths], 
      CAST([total_deaths] AS float) / CAST([total_cases] AS float) *100 AS Deathpercentage
FROM [dbo].[covid-data-deaths]
WHERE location LIKE '%Ecuador%'
and [continent] is not null
ORDER BY 1, 2;
```
Total de casos vs la Población, aquí se muestra que porcentaje de población tiene COVID.

```sql
SELECT [location], [date], [population],[total_cases], 
      CAST([total_cases] AS float) / CAST( [population]AS float) *100 AS PercentPopulationInfected
FROM [dbo].[covid-data-deaths]
ORDER BY 1, 2;
```
Países con tasas de infección mas alta en comparación con la población.
```sql
SELECT [location], [population], MAX([total_cases]) as HighestInfectionCount, 
      MAX(CAST([total_cases] AS float)) / CAST([population] AS float) * 100 AS PercentPopulationInfected
FROM [dbo].[covid-data-deaths]
GROUP BY [location], [population]
ORDER BY PercentPopulationInfected DESC
```
Países con mayor número de muertes por población.
```sql
SELECT [location], MAX(CAST([total_deaths] AS Int)) AS TotalDeathCount
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC
```
Continentes con mayor número de muertos por población.
```sql
SELECT [continent], MAX(CAST([total_deaths] AS Int)) AS TotalDeathCount
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC
```
Números globales, en caso de filtrar por fecha el número de casos.
```sql
SELECT [date], SUM([new_cases]) AS [total_cases],SUM(CAST([new_deaths] AS INT)) AS [total_deaths],
      CASE WHEN SUM([new_cases]) > 0 THEN (SUM(CAST([new_deaths] AS INT)) / NULLIF(SUM([new_cases]), 0)) * 100 
      ELSE NULL END AS DeathPercentage
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
GROUP BY [date]
ORDER BY 1, 2;
```
Verificamos por el número total de casos en el mundo.
```sql
SELECT SUM([new_cases]) AS [total_cases], SUM(CAST([new_deaths] AS INT)) AS [total_deaths], 
	   SUM(CAST([new_deaths] AS INT)) /SUM([new_cases]) *100 AS DeathPercentage
FROM [dbo].[covid-data-deaths]
WHERE [continent] IS NOT NULL
ORDER BY 1, 2;
```
Población total vs Vacunación
```sql
SELECT dea.[continent], dea.[location], dea.[date], dea.[population], vac.[new_vaccinations],
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.[location] ORDER BY dea.[location], dea.[Date])
AS RollingPeopleVaccinated
FROM [dbo].[covid-data-deaths] dea
JOIN [dbo].[covid-data-vaccinations] vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date] 
WHERE dea.[continent] IS NOT NULL
ORDER BY 2, 3
```
Uso de CTE para realizar el cálculo de la partición mediante la consulta anterior

```sql
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
```
Uso de la tabla temporal para realizar el cálculo de la partición en la consulta anterior

```sql
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
```
Creación de vista para almacenar datos para visualizaciones posteriores. 
```sql
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.[continent], dea.[location], dea.[date], dea.[population], vac.[new_vaccinations],
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.[location] ORDER BY dea.[location], dea.[Date])
AS RollingPeopleVaccinated
FROM [dbo].[covid-data-deaths] dea
JOIN [dbo].[covid-data-vaccinations] vac
	ON dea.[location] = vac.[location]
	AND dea.[date] = vac.[date]
WHERE [dea].[continent] IS NOT NULL

/*Verificamos nuestra vista*/

SELECT *
FROM PercentPopulationVaccinated
```
