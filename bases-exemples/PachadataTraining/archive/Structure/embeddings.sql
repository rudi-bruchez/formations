USE PachadataTraining;
GO

-- SELECT * FROM [Contact].[PreviousCoursesEmbeddings]
-- TRUNCATE TABLE [Contact].[PreviousCoursesEmbeddings]
CREATE TABLE [Contact].[PreviousCoursesEmbeddings]
(
	[PreviousCoursesEmbeddings] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NOT NULL,
	[EmbeddingType] [varchar](50) NOT NULL,
	[Embedding] [vector](1024, float32) NOT NULL,
	[ModelName] [nvarchar](100) NOT NULL,
	[ModelVersion] [nvarchar](50) NOT NULL,
	[GeneratedAt] [datetime2](3) NOT NULL,
	[SourceHash] [varbinary](32) NULL,
 CONSTRAINT [PK_PreviousCoursesEmbeddings] PRIMARY KEY CLUSTERED (
	[PreviousCoursesEmbeddings] ASC)
) WITH (DATA_COMPRESSION = ROW)
GO

ALTER TABLE [Contact].[PreviousCoursesEmbeddings] 
ADD  CONSTRAINT [DF_CourseEmbeddings_GeneratedAt]  
DEFAULT (sysutcdatetime()) FOR [GeneratedAt]
GO

ALTER TABLE [Contact].[PreviousCoursesEmbeddings]  
ADD  CONSTRAINT [FK_CourseEmbeddings_Course] FOREIGN KEY([ContactId])
REFERENCES [Contact].[Contact] ([ContactId])
ON DELETE CASCADE
GO

ALTER TABLE [Contact].[PreviousCoursesEmbeddings] CHECK CONSTRAINT [FK_CourseEmbeddings_Course]
GO
