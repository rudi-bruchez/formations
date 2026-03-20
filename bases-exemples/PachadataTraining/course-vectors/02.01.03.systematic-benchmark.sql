USE VectorBig;
GO

-- Schema
IF SCHEMA_ID('Benchmark') IS NULL EXEC('CREATE SCHEMA Benchmark');
GO

-- Benchmark table
DROP TABLE IF EXISTS Benchmark.BenchmarkResults;
GO

CREATE TABLE Benchmark.BenchmarkResults (
    ResultId INT IDENTITY(1, 1) PRIMARY KEY,
    TestName NVARCHAR(100) NOT NULL,
    TestDate DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    Rows BIGINT NOT NULL,
    Iterations INT NOT NULL,
    TopN INT NOT NULL,
    AvgMs DECIMAL(10,3) NOT NULL,
    MinMs DECIMAL(10,3) NULL,
    MaxMs DECIMAL(10,3) NULL,
    StdDevMs DECIMAL(10,3) NULL,
    P50Ms DECIMAL(10,3) NULL,
    P95Ms DECIMAL(10,3) NULL,
    P99Ms DECIMAL(10,3) NULL,
    IndexType NVARCHAR(50) NULL,
    Notes NVARCHAR(500) NULL
) WITH (DATA_COMPRESSION = ROW);
GO

-- VectorSearchBenchmark procedure
CREATE OR ALTER PROCEDURE Benchmark.VectorSearchBenchmark
    @TestName NVARCHAR(100),
    @Iterations INT = 100,
    @TopN INT = 10,
    @PersistResult bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS IO, TIME OFF;

    -- Temporary table for timing results
    CREATE TABLE #Results (
        IterationId INT PRIMARY KEY,
        ElapsedMicroseconds BIGINT
    );

    -- Sample query vectors from existing data
    DECLARE @QueryVectors TABLE (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        QueryVector VECTOR(1024)
    );

    INSERT INTO @QueryVectors (QueryVector)
    SELECT TOP (@Iterations) Embedding
    FROM Course.CourseEmbeddings
    ORDER BY NEWID();

    DECLARE @i INT = 1;
    DECLARE @Start DATETIME2(6);
    DECLARE @QueryVector VECTOR(1024);
    DECLARE @Rows BIGINT = (
        SELECT rows FROM sys.partitions p 
        WHERE p.object_id = OBJECT_ID('Course.CourseEmbeddings')
        AND p.index_id = 1
    );

    DECLARE @dummy TABLE (id int);

    WHILE @i <= @Iterations
    BEGIN
        SELECT @QueryVector = QueryVector FROM @QueryVectors WHERE Id = @i;

        SET @Start = SYSDATETIME();

        -- The query we're benchmarking
        INSERT INTO @dummy (id)
        SELECT TOP (@TopN) ce.CourseEmbeddingId
        FROM Course.CourseEmbeddings ce
        ORDER BY VECTOR_DISTANCE('cosine', @QueryVector, ce.Embedding)
        OPTION (MAXDOP 1);

        INSERT INTO #Results (IterationId, ElapsedMicroseconds)
        VALUES (@i, DATEDIFF_BIG(MICROSECOND, @Start, SYSDATETIME()));

        DELETE FROM @dummy;

        SET @i += 1;
    END

    -- Calculate statistics
    BEGIN TRAN;

    INSERT INTO Benchmark.BenchmarkResults
        (TestName, Rows, Iterations, TopN, AvgMs, MinMs, 
        MaxMs, StdDevMs, P50Ms, P95Ms, P99Ms)
    OUTPUT 
        INSERTED.TestName, 
        INSERTED.Rows, 
        INSERTED.Iterations, 
        INSERTED.TopN, 
        INSERTED.AvgMs, 
        INSERTED.MinMs, 
        INSERTED.MaxMs, 
        INSERTED.StdDevMs, 
        INSERTED.P50Ms, 
        INSERTED.P95Ms, 
        INSERTED.P99Ms
    SELECT
        @TestName AS TestName,
        @Rows as Rows,
        @Iterations AS Iterations,
        @TopN AS TopN,
        CAST(AVG(ElapsedMicroseconds) / 1000.0   AS decimal(8,2)) AS AvgMs,
        CAST(MIN(ElapsedMicroseconds) / 1000.0   AS decimal(8,2)) AS MinMs,
        CAST(MAX(ElapsedMicroseconds) / 1000.0   AS decimal(8,2)) AS MaxMs,
        CAST(STDEV(ElapsedMicroseconds) / 1000.0 AS decimal(8,2)) AS StdDevMs,
        CAST(p.P50Ms AS decimal(8,2)) AS P50Ms,
        CAST(p.P95Ms AS decimal(8,2)) AS P95Ms,
        CAST(p.P99Ms AS decimal(8,2)) AS P99Ms
    FROM #Results
    CROSS APPLY (
        SELECT
            PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ElapsedMicroseconds)
                OVER() / 1000.0 AS P50Ms,
            PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY ElapsedMicroseconds)
                OVER() / 1000.0 AS P95Ms,
            PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY ElapsedMicroseconds)
                OVER() / 1000.0 AS P99Ms
        FROM #Results
        WHERE ElapsedMicroseconds IS NOT NULL
    ) p
    GROUP BY p.P50Ms, p.P95Ms, p.P99Ms;

    IF @PersistResult = 1
        COMMIT;
    ELSE
        ROLLBACK;

    DROP TABLE #Results;
END;
GO
