---------------------------------------------------
--            VECTOR data type
---------------------------------------------------

IF DB_ID('VectorDemo') IS NULL
    CREATE DATABASE VectorDemo;
GO

USE VectorDemo;
GO

DROP TABLE IF EXISTS dbo.VectorDemo;
CREATE TABLE dbo.VectorDemo (
    Id INT PRIMARY KEY,
    Embedding VECTOR(3)
    -- Typically 384, 768, 1536, 3072 dimensions 
    -- depending on the embedding model
);
GO

-- Inserting some data
-- Vector values are represented as JSON arrays
INSERT INTO dbo.VectorDemo (Id, Embedding)
VALUES
    (1, '[0.1, 0.2, 0.3]'),
    (2, '[-0.5, 0.8, 0.1]'),
    (3, JSON_ARRAY(0.4, 0.5, 0.6));
GO

SELECT Id, Embedding FROM dbo.VectorDemo;
GO

-- Working with vectors in variables

DECLARE @v VECTOR(3) = '[0.1, 0.2, 0.3]';
SELECT @v AS MyVector;

-- I can also cast between types
DECLARE @json NVARCHAR(MAX) = '[0.7, 0.8, 0.9]';
SELECT CAST(@json AS VECTOR(3)) AS CastedVector;
GO

-- SQL Server 2025 supports vectors with 1 to 1,998 dimensions
-- when using the default float32 storage.

-- This works
CREATE TABLE dbo.LargeVector (
    Id INT PRIMARY KEY,
    Embedding VECTOR(1998)
);
DROP TABLE IF EXISTS dbo.LargeVector;

-- This fails
CREATE TABLE dbo.TooLargeVector (
    Id INT PRIMARY KEY,
    Embedding VECTOR(2000)
);

-- SQL Server 2025 supports half-precision floating 
-- point storage
-- Currently in preview
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

CREATE TABLE dbo.Float16Vector (
    Id INT PRIMARY KEY,
    Embedding VECTOR(3072, float16) NOT NULL
);
DROP TABLE IF EXISTS dbo.Float16Vector;
GO

ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = OFF;
GO

---------------------------------------------------
--            Storage calculation
---------------------------------------------------
SELECT
    1536 * 4 AS BytesPerEmbedding,
    -- one million courses :
    CAST(
        CAST(1536 as BIGINT) 
            * 4 * 1000000 / 1024.0 / 1024.0 / 1024.0 
        AS DECIMAL(10, 2))
        AS GigabytesForOneMillion;

---------------------------------------------------
--            Type limitations
---------------------------------------------------

-- This fails: no comparison operators
SELECT * FROM dbo.VectorDemo 
WHERE Embedding = '[0.1, 0.2, 0.3]';

-- This also fails: no mathematical operations
SELECT Embedding + '[0.1, 0.1, 0.1]' FROM dbo.VectorDemo;

-- And this: no constraints beyond NULL/NOT NULL
CREATE TABLE dbo.VectorWithCheck (
    Id INT PRIMARY KEY,
    Embedding VECTOR(3) CHECK (Embedding IS NOT NULL)  
    -- The CHECK syntax isn't supported
);
