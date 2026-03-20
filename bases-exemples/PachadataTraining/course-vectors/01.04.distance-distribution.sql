USE PachadataTraining;
GO

SELECT
    MIN(distance) OVER () AS MinDistance,
    AVG(distance) OVER () AS AvgDistance,
    MAX(distance) OVER () AS MaxDistance,
    PERCENTILE_CONT(0.1) WITHIN GROUP (ORDER BY distance) OVER () AS P10,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY distance) OVER () AS P50,
    PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY distance) OVER () AS P90
FROM (
    SELECT VECTOR_DISTANCE('cosine', e1.Embedding, e2.Embedding) AS distance
    FROM Course.CourseEmbeddings e1
    CROSS JOIN Course.CourseEmbeddings e2
    WHERE e1.CourseEmbeddingId < e2.CourseEmbeddingId
      AND e1.EmbeddingType = 'description'
      AND e2.EmbeddingType = 'description'
) distances;