USE PachadataTraining;
GO

-- Find all courses within a similarity threshold
DECLARE @query_vector VECTOR(1024) = (
	SELECT ce.Embedding
	FROM Course.Course c
	JOIN Course.CourseEmbeddings ce ON c.CourseId = ce.CourseId
	WHERE c.Title = 'Web Accessibility: Zero Trust Survival Guide (Core) #6591'
	AND ce.EmbeddingType = 'Title'
);

DECLARE @threshold FLOAT = 0.20;

SET STATISTICS IO, TIME ON;

SELECT CourseId, Title, distance
FROM (
    SELECT
        c.CourseId,
        c.Title,
        VECTOR_DISTANCE('cosine', @query_vector, ce.Embedding) AS distance
    FROM Course.CourseEmbeddings ce
    INNER JOIN Course.Course c ON ce.CourseId = c.CourseId
    WHERE ce.EmbeddingType = 'description'
) sub
WHERE distance < @threshold
ORDER BY distance;

SELECT
    c.CourseId,
    c.Title,
    VECTOR_DISTANCE('cosine', @query_vector, ce.Embedding) AS distance
FROM Course.CourseEmbeddings ce
INNER JOIN Course.Course c ON ce.CourseId = c.CourseId
WHERE ce.EmbeddingType = 'description'
  AND VECTOR_DISTANCE('cosine', @query_vector, ce.Embedding) < @threshold
ORDER BY distance;

