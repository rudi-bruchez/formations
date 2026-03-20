USE PachadataTraining;
GO
SET NOCOUNT ON;

/*
DELETE FROM [Course].[CourseEmbeddings];
DELETE FROM [Course].[Course];

DBCC CHECKIDENT ('[Course].[CourseEmbeddings]', RESEED, 0);
DBCC CHECKIDENT ('[Course].[Course]', RESEED, 0);
*/

DECLARE @TargetCount int = 10000;

-------------------------------------------------------------------------
-- 1) Load active sub-categories
-------------------------------------------------------------------------
DECLARE @SubCats TABLE
(
    RowNum int IDENTITY(1,1) PRIMARY KEY,
    CategoryId smallint NOT NULL,
    CategoryName nvarchar(100) NOT NULL,
    ParentCategoryName nvarchar(100) NOT NULL
);

INSERT INTO @SubCats (CategoryId, CategoryName, ParentCategoryName)
SELECT  c.CategoryId, c.CategoryName, p.CategoryName
FROM    Course.Category c
JOIN    Course.Category p ON p.CategoryId = c.ParentCategoryId
WHERE   c.ParentCategoryId IS NOT NULL
    AND   c.IsActive = 1
    AND   p.IsActive = 1;

IF NOT EXISTS (SELECT 1 FROM @SubCats)
    THROW 50001, 'No active sub-categories found in Course.Category.', 1;

DECLARE @SubCatCount int = (SELECT COUNT(*) FROM @SubCats);

-------------------------------------------------------------------------
-- 2) Dictionaries
-------------------------------------------------------------------------
DECLARE @Levels TABLE (Lvl tinyint PRIMARY KEY, Label nvarchar(30));
INSERT INTO @Levels (Lvl, Label)
VALUES (1,'Foundations'), (2,'Core'), (3,'Advanced'), (4,'Expert'), (5,'Masterclass'),
        (6,'Specialist'), (7,'Refresher'), (8,'Accelerated'), (9,'Professional');

DECLARE @Formats TABLE (Id int IDENTITY(1,1) PRIMARY KEY, Label nvarchar(30));
INSERT INTO @Formats(Label)
VALUES ('Bootcamp'), ('Deep Dive'), ('Hands-on Lab'), ('Workshop'), ('Crash Course'),
        ('Production Playbook'), ('Architecture Clinic'), ('Performance Tuning'), 
        ('Security Essentials'), ('Case Study Series'), ('Certification Prep'), 
        ('Intensive Sprint'), ('Technical Masterclass'), ('Survival Guide');

DECLARE @Focus TABLE (Id int IDENTITY(1,1) PRIMARY KEY, Label nvarchar(60));
INSERT INTO @Focus(Label)
VALUES ('Best Practices'), ('Design Patterns'), ('Troubleshooting'), ('Observability'),
        ('Scaling'), ('Cost Optimization'), ('Reliability'), ('Modernization'), 
        ('Governance'), ('Automation'), ('Zero Trust'), ('FinOps'), ('DevSecOps'),
        ('High Availability'), ('Disaster Recovery'), ('Technical Debt');

-------------------------------------------------------------------------
-- 3) RBAR generation
-------------------------------------------------------------------------
DECLARE
    @i int = 1,
    @CatRow int,
    @CategoryId smallint,
    @SubName nvarchar(100),
    @ParentName nvarchar(100),
    @TitleRaw nvarchar(200),
    @Title nvarchar(100),
    @Description nvarchar(2000),
    @Difficulty tinyint,
    @DurationDays tinyint,
    @PublishedDate date,
    @RetiredDate date,
    @LevelLabel nvarchar(30),
    @FormatLabel nvarchar(30),
    @FocusLabel nvarchar(60),
    @r int;

WHILE @i <= @TargetCount
BEGIN
    -- Random sub-category
    SET @CatRow = (ABS(CHECKSUM(NEWID())) % @SubCatCount) + 1;

    SELECT
        @CategoryId = CategoryId,
        @SubName = CategoryName,
        @ParentName = ParentCategoryName
    FROM @SubCats
    WHERE RowNum = @CatRow;

    -- Random marketing tokens
    SELECT @LevelLabel = Label
    FROM @Levels
    WHERE Lvl = (ABS(CHECKSUM(NEWID())) % (SELECT COUNT(*) FROM @Levels)) + 1;

    SELECT @FormatLabel = Label
    FROM @Formats
    WHERE Id = (ABS(CHECKSUM(NEWID())) % (SELECT COUNT(*) FROM @Formats)) + 1;

    SELECT @FocusLabel = Label
    FROM @Focus
    WHERE Id = (ABS(CHECKSUM(NEWID())) % (SELECT COUNT(*) FROM @Focus)) + 1;

    -- Difficulty skew 2-4
    SET @r = ABS(CHECKSUM(NEWID())) % 100;
    SET @Difficulty =
        CASE
            WHEN @r < 15 THEN 1
            WHEN @r < 45 THEN 2
            WHEN @r < 75 THEN 3
            WHEN @r < 92 THEN 4
            ELSE 5
        END;

    -- Duration skew 2-3
    SET @r = ABS(CHECKSUM(NEWID())) % 100;
    SET @DurationDays =
        CASE
            WHEN @r < 10 THEN 1
            WHEN @r < 40 THEN 2
            WHEN @r < 70 THEN 3
            WHEN @r < 90 THEN 4
            ELSE 5
        END;

    -- PublishedDate between now-5y and now-14d
    SET @PublishedDate = DATEADD(DAY, -14 - (ABS(CHECKSUM(NEWID())) % 1800), CAST(GETDATE() AS date));

    -- ~12% retired, after publish
    SET @RetiredDate =
        CASE
            WHEN (ABS(CHECKSUM(NEWID())) % 100) < 12
                THEN DATEADD(DAY, 60 + (ABS(CHECKSUM(NEWID())) % 900), @PublishedDate)
            ELSE NULL
        END;

    DECLARE @Suffix nvarchar(10) = CONCAT(' #', RIGHT('0000' + CAST(@i AS varchar(4)), 4));

    ---------------------------------------------------------------------
    -- Title patterns by known sub-category names (fallback included)
    ---------------------------------------------------------------------
    ---------------------------------------------------------------------
    -- Title patterns (Massively Expanded)
    ---------------------------------------------------------------------
    SET @TitleRaw =
    CASE
        -- DATA & DATABASES
        WHEN @SubName = 'SQL Server' THEN CONCAT('SQL Server: Query Store & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'PostgreSQL' THEN CONCAT('PostgreSQL: Indexing & ', @FocusLabel, ' (', @LevelLabel, ')', @Suffix)
        WHEN @SubName = 'MongoDB'    THEN CONCAT('MongoDB: Aggregation Pipeline & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Redis'      THEN CONCAT('Redis: Caching Strategies & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Data Warehousing' THEN CONCAT('Modern Data Warehouse: Dimensional Modeling ', @FormatLabel, @Suffix)
        WHEN @SubName = 'ETL & Data Pipelines' THEN CONCAT('Data Engineering: Airflow & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Big Data'   THEN CONCAT('Spark & Delta Lake: ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Snowflake'  THEN CONCAT('Snowflake: Cloud Data Sharing & ', @FocusLabel, @Suffix)

        -- DEVELOPMENT
        WHEN @SubName = 'Python'     THEN CONCAT('Python: AsyncIO & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Java'       THEN CONCAT('Java: Spring Boot Microservices & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'C#'         THEN CONCAT('.NET: Entity Framework Core & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'JavaScript' THEN CONCAT('TypeScript: Type Safety & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Go'         THEN CONCAT('Go: Microservices Architecture & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Rust'       THEN CONCAT('Rust: Memory Safety & ', @FocusLabel, ' (', @LevelLabel, ')', @Suffix)

        -- CLOUD & INFRA
        WHEN @SubName = 'Azure'      THEN CONCAT('Azure: Sentinel, Bicep & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'AWS'        THEN CONCAT('AWS: Serverless & ', @FocusLabel, ' (', @LevelLabel, ')', @Suffix)
        WHEN @SubName = 'Google Cloud' THEN CONCAT('GCP: Anthos & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Cloud Architecture' THEN CONCAT('Cloud Native: 12-Factor Apps & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Docker'     THEN CONCAT('Docker: Image Hardening & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Kubernetes' THEN CONCAT('K8s: GitOps with ArgoCD & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Terraform'  THEN CONCAT('Terraform: Module Design & ', @FocusLabel, ' ', @FormatLabel, @Suffix)

        -- SECURITY
        WHEN @SubName = 'Network Security' THEN CONCAT('Network: Zero Trust & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Cybersecurity'    THEN CONCAT('Cyber: Incident Response & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Identity Management' THEN CONCAT('IAM: OAuth2, OIDC & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Pentesting'       THEN CONCAT('Pentesting: Web API Exploitation ', @FormatLabel, @Suffix)

        -- AI & DATA SCIENCE
        WHEN @SubName = 'Machine Learning' THEN CONCAT('MLOps: Lifecycle & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Generative AI'    THEN CONCAT('GenAI: RAG & Prompt Engineering ', @FormatLabel, @Suffix)
        WHEN @SubName = 'NLP'              THEN CONCAT('NLP: Large Language Models & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Data Visualization' THEN CONCAT('DataViz: PowerBI & Storytelling ', @FormatLabel, @Suffix)

        -- FRONTEND & MOBILE
        WHEN @SubName = 'React'      THEN CONCAT('React: Advanced Hooks & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Angular'    THEN CONCAT('Angular: Signals & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Vue'        THEN CONCAT('Vue 3: Composition API & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'Flutter'    THEN CONCAT('Flutter: State Management & ', @FocusLabel, @Suffix)
        WHEN @SubName = 'iOS Development' THEN CONCAT('SwiftUI: Architecture & ', @FocusLabel, @Suffix)

        -- BUSINESS & OPS
        WHEN @SubName = 'Agile'      THEN CONCAT('Agile: Scaling Scrums & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'DevOps'     THEN CONCAT('DevOps: DORA Metrics & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
        WHEN @SubName = 'Product Management' THEN CONCAT('Product: Strategy & ', @FocusLabel, ' ', @FormatLabel, @Suffix)

        ELSE CONCAT(@SubName, ': ', @FocusLabel, ' ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
    END;

    -- Hard cap to 100 characters (table column is nvarchar(100))
    SET @Title = LEFT(@TitleRaw, 100);

    SET @Description = CONCAT(
        'Category: ', @ParentName, ' / ', @SubName, '. ',
        'Format: ', @FormatLabel, '. ',
        'Focus: ', @FocusLabel, '. ',
        'Level: ', @LevelLabel, '. ',
        'Includes guided labs, checklists, common pitfalls, and production-ready practices.'
    );

    INSERT INTO Course.Course
    (
        CategoryId,
        Title,
        Description,
        DifficultyLevel,
        PublishedDate,
        RetiredDate,
        DurationDays
    )
    VALUES
    (
        @CategoryId,
        @Title,
        @Description,
        @Difficulty,
        @PublishedDate,
        @RetiredDate,
        @DurationDays
    );

    SET @i += 1;
END

-- checks
SELECT COUNT(*) FROM Course.Course;
SELECT TOP 100 * FROM Course.Course;
