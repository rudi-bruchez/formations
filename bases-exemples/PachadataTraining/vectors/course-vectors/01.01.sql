USE PachadataTraining;
GO

SET STATISTICS TIME ON;
GO

DECLARE @query_vector VECTOR(1024) = (
	SELECT Embedding
	FROM Course.CourseEmbeddings 
	WHERE CourseEmbeddingId = 1662
)

;WITH cte AS (
	SELECT 
		ce.CourseId,
		VECTOR_DISTANCE('cosine', @query_vector, ce.Embedding) AS distance
	FROM Course.CourseEmbeddings ce
)
SELECT 
	c.Title,
	c.Description,
	ce.*
FROM cte ce
JOIN Course.Course c ON ce.CourseId = c.CourseId
WHERE distance < 0.05
ORDER BY distance
OPTION (MAXDOP 1);