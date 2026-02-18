CREATE DATABASE VectorDemo;
GO

USE VectorDemo;
GO

CREATE TABLE dbo.VectorDemo (
    Id INT PRIMARY KEY,
    Embedding VECTOR(3)
);
GO

-- This fails: no comparison operators
SELECT * FROM dbo.VectorDemo WHERE Embedding = '[0.1, 0.2, 0.3]';

-- This also fails: no mathematical operations
SELECT Embedding + '[0.1, 0.1, 0.1]' FROM dbo.VectorDemo;

-- And this: no constraints beyond NULL/NOT NULL
CREATE TABLE dbo.VectorWithCheck (
    Id INT PRIMARY KEY,
    Embedding VECTOR(3) CHECK (Embedding IS NOT NULL)  -- The CHECK syntax isn't supported
);
