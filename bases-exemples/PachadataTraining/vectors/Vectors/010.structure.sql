USE PachadataTraining;
GO

-- DROP TABLE Course.CourseEmbeddings

CREATE TABLE Course.CourseEmbeddings
(
    CourseEmbeddingId bigint IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_CourseEmbeddings PRIMARY KEY,
    CourseId              int NOT NULL,
    EmbeddingType         varchar(50) NOT NULL,
    Embedding             vector(1024) NOT NULL,
    -- e.g. 'text-embedding-3-large'
    ModelName             nvarchar(100) NOT NULL,
    -- Semantic version or internal versioning
    ModelVersion          nvarchar(50) NOT NULL,
    GeneratedAt           datetime2(3) NOT NULL
        CONSTRAINT DF_CourseEmbeddings_GeneratedAt
        DEFAULT sysutcdatetime(),
    -- hash of source text for regeneration detection
    SourceHash            varbinary(32) NULL,

    CONSTRAINT FK_CourseEmbeddings_Course
        FOREIGN KEY (CourseId)
        REFERENCES Course.Course(CourseId)
        ON DELETE CASCADE
);
GO
