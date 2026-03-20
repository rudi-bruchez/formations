SELECT *
FROM Course.Course c
WHERE c.Description LIKE '%Python%reliability%';

SELECT c.Title, c.Description, ce.EmbeddingType, ce.Embedding
FROM Course.CourseEmbeddings ce
JOIN Course.Course c ON ce.CourseId = c.CourseId
WHERE c.CourseId = 160;

