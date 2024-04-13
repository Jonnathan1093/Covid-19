USE [Data-Projects]
GO

/*Estandarizar formato de fechas*/ 

SELECT [SaleDateConverted], CONVERT(DATE, [SaleDate])
FROM [dbo].[Nashville-Housing]

UPDATE [Nashville-Housing]
SET [SaleDate] = CONVERT(DATE, [SaleDate])

/* En caso de que no se actualiza correctamente */

ALTER TABLE [Nashville-Housing] 
ADD [SaleDateConverted] DATE;

UPDATE [Nashville-Housing]
SET [SaleDateConverted] = CONVERT(DATE, [SaleDate])

/*Completar datos de dirección de propiedad*/

SELECT *
FROM [dbo].[Nashville-Housing]
--WHERE [PropertyAddress] IS NULL
ORDER BY [ParcelID]

/*Realizamos una auto union para comparar y completar datos*/

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

/*Dividir la dirección en columnas individuales (Dirección, Ciudad, Estado)*/

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

/*Método mas sencillo para realizar la partición de datos de acuerdo a lo anterior*/

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

/*Cambie Y por Yes y N por No en el campo "Sold as Vacant"*/

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

/*Eliminamos duplicados*/

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

SELECT *
FROM [dbo].[Nashville-Housing]

/*Eliminar columnas innecesarias*/

SELECT *
FROM [dbo].[Nashville-Housing]

ALTER TABLE [Nashville-Housing]
DROP COLUMN [OwnerAddress], [TaxDistrict], [PropertyAddress], [SaleDate]





