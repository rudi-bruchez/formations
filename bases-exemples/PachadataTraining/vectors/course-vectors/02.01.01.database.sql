CREATE DATABASE VectorBig
 ON  
( NAME = N'VectorBig', FILENAME = N'/var/opt/mssql/data/VectorBig.mdf' , 
  SIZE = 5GB , FILEGROWTH = 64MB )
 LOG ON 
( NAME = N'VectorBig_log', FILENAME = N'/var/opt/mssql/data/VectorBig_log.ldf' , 
  SIZE = 500MB , FILEGROWTH = 64MB )
GO
ALTER DATABASE VectorBig SET RECOVERY SIMPLE 
ALTER DATABASE VectorBig SET TARGET_RECOVERY_TIME = 60 SECONDS 
ALTER DATABASE VectorBig SET DELAYED_DURABILITY = FORCED
ALTER DATABASE VectorBig SET ACCELERATED_DATABASE_RECOVERY = ON  
GO
ALTER DATABASE VectorBig SET OPTIMIZED_LOCKING = ON
GO

USE VectorBig
GO

-- Schema
IF SCHEMA_ID('Course') IS NULL EXEC('CREATE SCHEMA Course');
GO

-- Benchmark table
DROP TABLE IF EXISTS Course.CourseEmbeddings;
GO

CREATE TABLE Course.CourseEmbeddings(
  CourseEmbeddingId int IDENTITY(1,1) NOT NULL,
  Embedding vector(1024, float32) NOT NULL,
  CONSTRAINT PK_CourseEmbeddings 
    PRIMARY KEY CLUSTERED (CourseEmbeddingId)
) WITH (DATA_COMPRESSION = ROW)
GO

INSERT INTO Course.CourseEmbeddings (Embedding)
SELECT Embedding
FROM PachadataTraining.Course.CourseEmbeddings
GO 20
