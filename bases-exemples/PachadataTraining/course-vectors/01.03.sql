USE PachadataTraining;
GO

-------------------------------------------------------------
--                 Course.Category
-------------------------------------------------------------
CREATE TABLE Course.Category (
	CategoryId smallint IDENTITY(1,1) NOT NULL,
	CategoryName nvarchar(100) NULL,
	ParentCategoryId smallint NULL,
	IsActive bit NOT NULL DEFAULT ((1)),
    CONSTRAINT pk_Category PRIMARY KEY CLUSTERED (CategoryId),
    CONSTRAINT uq_CategoryCategoryName UNIQUE (CategoryName) 
)
GO

-------------------------------------------------------------
--                 Course.Course
-------------------------------------------------------------
CREATE TABLE Course.Course (
	CourseId int IDENTITY(1,1) NOT NULL,
	CategoryId smallint NOT NULL,
	Title nvarchar(100) NOT NULL,
	Description nvarchar(2000) NOT NULL,
	DifficultyLevel tinyint NOT NULL DEFAULT ((1)),
	PublishedDate date NOT NULL,
	RetiredDate date NULL,
	DurationDays tinyint NOT NULL,
    CONSTRAINT pk_Course PRIMARY KEY CLUSTERED (CourseId),
    CONSTRAINT uq_Course_CourseName UNIQUE (Title),
	CONSTRAINT chk_Course_DifficultyLevel CHECK (DifficultyLevel BETWEEN 1 AND 5)
) WITH (DATA_COMPRESSION = ROW);
GO

-------------------------------------------------------------
--                 Course.CourseEmbeddings
-------------------------------------------------------------
CREATE TABLE Course.CourseEmbeddings (
	CourseEmbeddingId bigint IDENTITY(1,1) NOT NULL,
	CourseId int NOT NULL,
	EmbeddingType varchar(50) NOT NULL,
	Embedding vector(1024, float32) NOT NULL,
	ModelName nvarchar(100) NOT NULL,
	ModelVersion nvarchar(50) NOT NULL,
	GeneratedAt datetime2(3) NOT NULL,
	SourceHash varbinary(32) NULL,
    CONSTRAINT PK_CourseEmbeddings PRIMARY KEY CLUSTERED (CourseEmbeddingId),
	CONSTRAINT DF_CourseEmbeddings_GeneratedAt DEFAULT (sysutcdatetime()) FOR GeneratedAt,
	CONSTRAINT FK_CourseEmbeddings_Course FOREIGN KEY(CourseId)
        REFERENCES Course.Course (CourseId)
		ON DELETE CASCADE
) WITH (DATA_COMPRESSION = ROW);
GO

-------------------------------------------------------------
--                       Indexes
-------------------------------------------------------------
-- DROP INDEX ix_Course_Category ON Course.Course;
CREATE INDEX ix_Course_Category
ON Course.Course (CategoryId)
INCLUDE (Title, RetiredDate)
WITH (ONLINE = ON, DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON);

--                   CourseEmbeddings

-- DROP INDEX ix_CourseEmbeddings_CourseId ON Course.CourseEmbeddings;
CREATE INDEX ix_CourseEmbeddings_CourseId
ON Course.CourseEmbeddings (CourseId, EmbeddingType)
WITH (ONLINE = ON, DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON);


-------------------------------------------------------------
--                    DON'T DO THIS
-------------------------------------------------------------
CREATE TABLE Course.BadSchemaOverwide (
    CourseId INT PRIMARY KEY,
    Title NVARCHAR(200),
    TitleEmbedding VECTOR(1024),
    DescriptionEmbedding VECTOR(1024),
    SummaryEmbedding VECTOR(1024)
);

-- Don't do this either
CREATE TABLE dbo.BadSchemaStringKey (
    SKU NVARCHAR(50) PRIMARY KEY,
    ProductName NVARCHAR(200),
    Embedding VECTOR(1024)
);

-- because ...
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;

CREATE VECTOR INDEX no_need_to_name_it
ON dbo.BadSchemaStringKey (Embedding)
WITH (METRIC = 'cosine', TYPE = 'DiskANN');

ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = OFF;

-- DROP TABLE dbo.BadSchemaStringKey;
