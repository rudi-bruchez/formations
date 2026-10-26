USE PachadataTraining;
GO

EXEC Benchmark.VectorSearchBenchmark
    @TestName = 'ENN_Baseline_OrderByDistance',
    @Iterations = 100,
    @TopN = 10;

-- Run filtered benchmark
EXEC Benchmark.VectorSearchFilteredBenchmark
    @TestName = 'ENN_Filtered_Category[Predictive Analytics]',
    @CategoryName = N'Predictive Analytics',
    @Iterations = 100;

SELECT *
FROM Benchmark.BenchmarkResults;