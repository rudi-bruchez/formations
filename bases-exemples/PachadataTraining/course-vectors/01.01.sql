USE PachadataTraining;
GO

SET STATISTICS TIME ON;
GO

DECLARE @query_vector VECTOR(1024) = (
	SELECT Embedding
	FROM Course.CourseEmbeddings 
	WHERE CourseEmbeddingId = 1662
)

SELECT TOP 10
    ce.CourseId,
    c.Title,
    VECTOR_DISTANCE('cosine', @query_vector, ce.Embedding) AS distance
FROM Course.CourseEmbeddings ce
JOIN Course.Course c ON ce.CourseId = c.CourseId
ORDER BY distance;