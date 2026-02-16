USE PachadataTraining;
GO

CREATE SCHEMA Travel;
GO

DROP TABLE IF EXISTS Travel.Restaurant;
GO
CREATE TABLE Travel.Restaurant (
    RestaurantId smallint NOT NULL CONSTRAINT pk_Restaurant PRIMARY KEY,
    JsonInfo JSON NOT NULL,
    ClobInfo NVARCHAR(MAX) COLLATE Latin1_General_BIN2 NOT NULL

);
GO

INSERT INTO Travel.Restaurant (RestaurantId, JsonInfo, ClobInfo)
SELECT j.[key], j.value, CAST(j.value AS NVARCHAR(MAX))
FROM OPENROWSET(BULK '/var/opt/mssql/backups/restaurants.json', SINGLE_CLOB) o
CROSS APPLY OPENJSON(o.BulkColumn) j;

CREATE JSON INDEX IXJ_Restaurant_JsonInfo_Name
ON Travel.Restaurant (JsonInfo)
FOR (N'$.name')
WITH (FILLFACTOR = 90);