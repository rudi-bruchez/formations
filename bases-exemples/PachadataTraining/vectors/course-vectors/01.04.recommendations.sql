USE PachadataTraining;
GO

-- Find similar courses for multiple students at once
SELECT
    co.ContactId,
    CONCAT_WS(' ', co.FirstName, co.LastName) as Student,
    r.RecommendedCourseId,
    r.Title,
    r.distance
FROM Contact.Contact co
JOIN Contact.PreviousCoursesEmbeddings pce ON pce.ContactId = co.ContactId
    AND pce.EmbeddingType = 'Description'
CROSS APPLY (
    SELECT TOP 3
        c.CourseId AS RecommendedCourseId,
        c.Title,
        VECTOR_DISTANCE('cosine', pce.Embedding, ce.Embedding) AS distance
    FROM Course.CourseEmbeddings ce
    JOIN Course.Course c ON ce.CourseId = c.CourseId
    WHERE ce.EmbeddingType = 'description'
      AND c.CourseId NOT IN (SELECT SessionId FROM Enrollment.Enrollment 
      WHERE ContactId = co.ContactId)
    ORDER BY distance
) r;

