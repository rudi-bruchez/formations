USE VectorBig;
GO

SELECT rows FROM sys.partitions p 
WHERE p.object_id = OBJECT_ID('Course.CourseEmbeddings')
AND p.index_id = 1
GO

DECLARE @qv VECTOR(1024) = (
	SELECT TOP 1 Embedding FROM Course.CourseEmbeddings
);

SET STATISTICS TIME ON;

SELECT TOP 10 CourseEmbeddingId
FROM Course.CourseEmbeddings
ORDER BY VECTOR_DISTANCE('cosine', @qv, Embedding)
OPTION (MAXDOP 1);

SET STATISTICS TIME OFF;

-- After we created the stored procedure
EXEC Benchmark.VectorSearchBenchmark
    @TestName = 'ENN_Baseline_OrderByDistance',
    @Iterations = 10,
    @TopN = 10;
GO

-- Cost of IO
DECLARE @qv VECTOR(1024) = (
	SELECT TOP 1 Embedding FROM Course.CourseEmbeddings
);

SET STATISTICS IO, TIME ON;

SELECT TOP 10 CourseEmbeddingId
FROM Course.CourseEmbeddings
WHERE CourseEmbeddingId % 10 = 0
ORDER BY VECTOR_DISTANCE('cosine', @qv, Embedding)
OPTION (MAXDOP 1);

SELECT COUNT(*)
FROM Course.CourseEmbeddings
OPTION (MAXDOP 1);

SET STATISTICS IO, TIME OFF;
