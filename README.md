# COVID-19
<div style="text-align: justify;">
Este repositorio incluye datasets con los eventos registrados del COVID-19 desde 10 de Enero del 2020, hasta el 24 de Marzo del 2024.
<p>

**La información lo pueden encontrar en la siguiente dirección:**
- https://ourworldindata.org/covid-deaths

</div>

![Data](https://github.com/Jonnathan1093/Covid-19/assets/90915190/eaec4dcf-c90c-444a-84ce-29708db03f12)

## EXPLORACIÓN DE DATOS:
<div style="text-align: justify;">
En esta etapa se realizo una exploración de datos con respecto a la información obtenida del COVID-19, en este proceso se analizo y visualizan los datos relacionados con la pandemia. Durante esta exploración, se pudo ver el número de casos confirmados, tasas de mortalidad, distribución geográfica, efectividad de las vacunas y más.
</div>


## SQL QUERIES:
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
# LIMPIEZA DE DATOS CON SQL QUERIES

<div style="text-align: justify;">
 En esta sección realizaremos una exploración y limpieza de datos del archivo "Nashville Housing Data for Data Cleaning", este archivo excel a sido previamente cargado a nuestro SQL Management Studio para poder realizar su respectiva limpieza.
</div>

## QUERIES SQL

Estandarizar el formato de fechas.
```sql
SELECT [SaleDateConverted], CONVERT(DATE, [SaleDate])
FROM [dbo].[Nashville-Housing]

UPDATE [Nashville-Housing]
SET [SaleDate] = CONVERT(DATE, [SaleDate])

/* En caso de que no se actualiza correctamente */

ALTER TABLE [Nashville-Housing] 
ADD [SaleDateConverted] DATE;

UPDATE [Nashville-Housing]
SET [SaleDateConverted] = CONVERT(DATE, [SaleDate])
```

Completar datos de dirección de propiedad.
```sql
SELECT *
FROM [dbo].[Nashville-Housing]
--WHERE [PropertyAddress] IS NULL
ORDER BY [ParcelID]

/*Realizamos una auto-union para comparar y completar datos*/

SELECT a.[ParcelID], a.[PropertyAddress], b.[ParcelID], b.[PropertyAddress], ISNULL(a.[PropertyAddress],b.[PropertyAddress])
FROM dbo.[Nashville-Housing] a
JOIN dbo.[Nashville-Housing] b
	on a.[ParcelID] = b.[ParcelID]
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.[PropertyAddress] IS NULL

/*Actualizamos la información*/

UPDATE a
SET [PropertyAddress] = ISNULL(a.[PropertyAddress],b.[PropertyAddress])
FROM dbo.[Nashville-Housing] a
JOIN dbo.[Nashville-Housing] b
    on a.[ParcelID] = b.[ParcelID]
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.[PropertyAddress] IS NULL
```
Dividir la dirección en columnas individuales (Dirección, Ciudad, Estado).
```sql
SELECT [PropertyAddress]
FROM [dbo].[Nashville-Housing]

/*Utilizamos SUBSTRING y CHARINDEX*/
SELECT
SUBSTRING([PropertyAddress], 1, CHARINDEX(',', [PropertyAddress]) -1) AS [Address],
SUBSTRING([PropertyAddress], CHARINDEX(',', [PropertyAddress]) + 1, LEN([PropertyAddress])) AS [City]
FROM [dbo].[Nashville-Housing]

/* Creamos columnas nuevas*/

ALTER TABLE [Nashville-Housing]
ADD [PropertySplitAddress] NVARCHAR(255);

ALTER TABLE [Nashville-Housing]
ADD [PropertySplitCity] NVARCHAR(255);

/*Actualizamos la información*/

UPDATE [Nashville-Housing]
SET [PropertySplitAddress] = SUBSTRING([PropertyAddress], 1, CHARINDEX(',', [PropertyAddress]) -1)

UPDATE [Nashville-Housing]
SET [PropertySplitCity] = SUBSTRING([PropertyAddress], CHARINDEX(',', [PropertyAddress]) + 1, LEN([PropertyAddress]))

SELECT *
FROM [dbo].[Nashville-Housing]
```
Método mas sencillo para realizar la partición de datos de acuerdo a lo anterior.
```sql
SELECT [OwnerAddress]
FROM [dbo].[Nashville-Housing]

SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM [dbo].[Nashville-Housing]

/*Alteramos columnas y actualizamos la información*/

ALTER TABLE [Nashville-Housing]
ADD [OwnerSplitAddress] NVARCHAR(255);

UPDATE [Nashville-Housing]
SET [OwnerSplitAddress] = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE [Nashville-Housing]
ADD [OwnerSplitCity] NVARCHAR(255);

UPDATE [Nashville-Housing]
SET [OwnerSplitCity] = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE [Nashville-Housing]
ADD [OwnerSplitState] NVARCHAR(255);

UPDATE [Nashville-Housing]
SET [OwnerSplitState] = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

SELECT *
FROM [dbo].[Nashville-Housing]
```
Cambie Y por Yes y N por No en el campo "Sold as Vacant"
```sql
SELECT DISTINCT([SoldAsVacant]), COUNT([SoldAsVacant])
FROM [dbo].[Nashville-Housing]
GROUP BY [SoldAsVacant]
ORDER BY 2

/*Seleccionamos y reemplazamos*/

SELECT [SoldAsVacant]
, CASE WHEN [SoldAsVacant] = 'Y' THEN 'Yes'
       WHEN [SoldAsVacant] = 'N' THEN 'No'
       ELSE [SoldAsVacant]
       END
FROM [dbo].[Nashville-Housing]

/*Actualizamos la información*/

UPDATE [Nashville-Housing]
SET [SoldAsVacant] = CASE WHEN [SoldAsVacant] = 'Y' THEN 'Yes'
       WHEN [SoldAsVacant] = 'N' THEN 'No'
       ELSE [SoldAsVacant]
       END
```
Eliminamos duplicados
```sql
WITH [RowNumCTE] AS(
SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY [ParcelID],
                 [PropertyAddress],
                 [SalePrice],
                 [SaleDate],
                 [LegalReference]
                 ORDER BY
                    [UniqueID]
                    ) row_num
FROM [dbo].[Nashville-Housing]
--ORDER BY ParcelID
)
SELECT *
--DELETE
FROM [RowNumCTE]
WHERE row_num > 1
ORDER BY [PropertyAddress]
```
Eliminar columnas innecesarias
```sql
SELECT *
FROM [dbo].[Nashville-Housing]

ALTER TABLE [Nashville-Housing]
DROP COLUMN [OwnerAddress], [TaxDistrict], [PropertyAddress], [SaleDate]
```