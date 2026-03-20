USE PachadataTraining;
GO

CREATE OR ALTER PROCEDURE Benchmark.VectorSearchFilteredBenchmark
    @TestName NVARCHAR(100),
    @CategoryName NVARCHAR(100) = N'Generative AI',
    @Iterations INT = 100,
    @TopN INT = 10,
    @EmbeddingType NVARCHAR(50) = 'description',
    @PersistResult bit = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET STATISTICS IO, TIME OFF;

    CREATE TABLE #Results (
        IterationId INT PRIMARY KEY,
        ElapsedMicroseconds BIGINT
    );

    DECLARE @QueryVectors TABLE (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        QueryVector VECTOR(1024)
    );

    DECLARE @CategoryId smallint = (
        SELECT CategoryId
        FROM Course.Category
        WHERE CategoryName = @CategoryName
    );

    DECLARE @Rows BIGINT = (
        SELECT COUNT(*)
        FROM Course.CourseEmbeddings ce
        JOIN Course.Course c ON ce.CourseId = c.CourseId
        WHERE c.CategoryId = @CategoryId
          AND ce.EmbeddingType = @EmbeddingType
          AND c.RetiredDate IS NULL
    )

    INSERT INTO @QueryVectors (QueryVector)
    SELECT TOP (@Iterations) ce.Embedding
    FROM Course.CourseEmbeddings ce
    JOIN Course.Course c ON ce.CourseId = c.CourseId
    WHERE c.CategoryId = @CategoryId
      AND ce.EmbeddingType = @EmbeddingType
      AND c.RetiredDate IS NULL
    ORDER BY NEWID();

    DECLARE @i INT = 1;
    DECLARE @Start DATETIME2(7);
    DECLARE @QueryVector VECTOR(1024);
    
    DECLARE @dummy TABLE (id int);

    WHILE @i <= @Iterations
    BEGIN
        SELECT @QueryVector = QueryVector FROM @QueryVectors WHERE Id = @i;

        SET @Start = SYSDATETIME();

        INSERT INTO @dummy (id)
        SELECT TOP (@TopN) ce.CourseId
        FROM Course.CourseEmbeddings ce
        JOIN Course.Course c ON ce.CourseId = c.CourseId
        WHERE ce.EmbeddingType = @EmbeddingType
          AND c.CategoryId = @CategoryId
          AND c.RetiredDate IS NULL
        ORDER BY VECTOR_DISTANCE('cosine', @QueryVector, ce.Embedding);

        INSERT INTO #Results VALUES (@i, DATEDIFF_BIG(MICROSECOND, @Start, SYSDATETIME()));
        SET @i += 1;
    END

    -- Calculate statistics
    BEGIN TRAN;

    INSERT INTO Benchmark.BenchmarkResults
        (TestName, Rows, Iterations, TopN, AvgMs, P95Ms)
    OUTPUT 
        INSERTED.TestName, 
        INSERTED.Rows, 
        INSERTED.Iterations, 
        INSERTED.TopN, 
        INSERTED.AvgMs, 
        INSERTED.P95Ms
    SELECT
        @TestName AS TestName,
        @Rows as Rows,
        @Iterations AS Iterations,
        @TopN AS TopN,
        CAST(AVG(ElapsedMicroseconds) / 1000.0 AS decimal(8,2)) AS AvgMs,
        CAST(p.P95Ms AS decimal(8,2)) AS P95Ms
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

