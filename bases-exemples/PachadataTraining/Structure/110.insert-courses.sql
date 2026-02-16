USE PachadataTraining;
GO
SET NOCOUNT ON;

DECLARE @TargetCount int = 800;

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
    -- 2) Dictionaries (short but effective)
    -------------------------------------------------------------------------
    DECLARE @Levels TABLE (Lvl tinyint PRIMARY KEY, Label nvarchar(30));
    INSERT INTO @Levels (Lvl, Label)
    VALUES (1,'Foundations'), (2,'Core'), (3,'Advanced'), (4,'Expert'), (5,'Masterclass');

    DECLARE @Formats TABLE (Id int IDENTITY(1,1) PRIMARY KEY, Label nvarchar(30));
    INSERT INTO @Formats(Label)
    VALUES ('Bootcamp'), ('Deep Dive'), ('Hands-on Lab'), ('Workshop'), ('Crash Course'),
           ('Production Playbook'), ('Architecture Clinic'), ('Performance Tuning'), ('Security Essentials');

    DECLARE @Focus TABLE (Id int IDENTITY(1,1) PRIMARY KEY, Label nvarchar(60));
    INSERT INTO @Focus(Label)
    VALUES ('Best Practices'), ('Design Patterns'), ('Troubleshooting'), ('Observability'),
           ('Scaling'), ('Cost Optimization'), ('Reliability'), ('Modernization'), ('Governance'), ('Automation');

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
        WHERE Lvl = (ABS(CHECKSUM(NEWID())) % 5) + 1;

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
        SET @TitleRaw =
        CASE
            WHEN @SubName = 'SQL Server' THEN CONCAT('SQL Server: Query Store ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
            WHEN @SubName = 'PostgreSQL' THEN CONCAT('PostgreSQL: Indexing, Planner & ', @FocusLabel, ' (', @LevelLabel, ')', @Suffix)
            WHEN @SubName = 'Data Warehousing' THEN CONCAT('Modern Data Warehouse: Dimensional Modeling ', @FormatLabel, @Suffix)
            WHEN @SubName = 'ETL & Data Pipelines' THEN CONCAT('ETL Pipelines: Orchestration & Data Quality ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Big Data' THEN CONCAT('Big Data Systems: Partitioning, Formats & ', @FocusLabel, @Suffix)

            WHEN @SubName = 'Python' THEN CONCAT('Python: Packaging, Testing & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Java' THEN CONCAT('Java: JVM Performance & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'C#' THEN CONCAT('.NET: Async, Memory & Diagnostics ', @FormatLabel, @Suffix)
            WHEN @SubName = 'JavaScript' THEN CONCAT('JavaScript: Modern Tooling & Web ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Go' THEN CONCAT('Go: Concurrency, Profiling & ', @FocusLabel, ' ', @FormatLabel, @Suffix)

            WHEN @SubName = 'Azure' THEN CONCAT('Azure: Landing Zone & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'AWS' THEN CONCAT('AWS: Well-Architected ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
            WHEN @SubName = 'Google Cloud' THEN CONCAT('Google Cloud: IAM, Networking & ', @FocusLabel, @Suffix)
            WHEN @SubName = 'Cloud Architecture' THEN CONCAT('Cloud Architecture: ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Serverless Computing' THEN CONCAT('Serverless: Event-Driven ', @FormatLabel, ' & ', @FocusLabel, @Suffix)

            WHEN @SubName = 'Machine Learning' THEN CONCAT('Machine Learning: Feature Engineering ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Statistical Analysis' THEN CONCAT('Statistics: Inference, Confidence & ', @FocusLabel, @Suffix)
            WHEN @SubName = 'Data Visualization' THEN CONCAT('Data Visualization: Storytelling ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
            WHEN @SubName = 'Business Intelligence' THEN CONCAT('BI: Modeling, Metrics & Governance ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Predictive Analytics' THEN CONCAT('Predictive Analytics: From Baselines to Production ', @FormatLabel, @Suffix)

            WHEN @SubName = 'CI/CD Pipelines' THEN CONCAT('CI/CD: Release Strategies & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Containerization' THEN CONCAT('Containers: Images, Security & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Kubernetes' THEN CONCAT('Kubernetes: Operations ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
            WHEN @SubName = 'Infrastructure as Code' THEN CONCAT('IaC: Terraform Patterns & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Monitoring & Logging' THEN CONCAT('Observability: Logs, Metrics & Traces ', @FormatLabel, @Suffix)

            WHEN @SubName = 'Network Security' THEN CONCAT('Network Security: Segmentation & Zero Trust ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Application Security' THEN CONCAT('AppSec: Threat Modeling & Secure SDLC ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Ethical Hacking' THEN CONCAT('Ethical Hacking: Recon to Exploit ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Cloud Security' THEN CONCAT('Cloud Security: IAM, Secrets & ', @FocusLabel, @Suffix)
            WHEN @SubName = 'Compliance & Governance' THEN CONCAT('Compliance: Controls, Evidence & Audit ', @FormatLabel, @Suffix)

            WHEN @SubName = 'Natural Language Processing' THEN CONCAT('NLP: Tokenization to Transformers ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Computer Vision' THEN CONCAT('Computer Vision: Detection, Segmentation & Deployment ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Generative AI' THEN CONCAT('Generative AI: RAG, Agents & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'AI Ethics' THEN CONCAT('AI Ethics: Bias, Safety & Governance ', @FormatLabel, @Suffix)
            WHEN @SubName = 'AI in Business' THEN CONCAT('AI for Business: Use Cases, ROI & ', @FocusLabel, @Suffix)

            WHEN @SubName = 'Frontend Development' THEN CONCAT('Frontend: Performance, Accessibility & DX ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Backend Development' THEN CONCAT('Backend: APIs, Scaling & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Full Stack Development' THEN CONCAT('Full Stack: From MVP to Production ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Web Performance' THEN CONCAT('Web Performance: Core Web Vitals ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Web Accessibility' THEN CONCAT('Web Accessibility: WCAG in Practice ', @FormatLabel, @Suffix)

            WHEN @SubName = 'iOS Development' THEN CONCAT('iOS: Swift Concurrency & Architecture ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Android Development' THEN CONCAT('Android: Modern App Architecture ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Cross-Platform Development' THEN CONCAT('Cross-Platform: Architecture & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Mobile UI/UX' THEN CONCAT('Mobile UI/UX: Research to Prototyping ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Mobile Security' THEN CONCAT('Mobile Security: Hardening & Secure Storage ', @FormatLabel, @Suffix)

            WHEN @SubName = 'Unity Game Development' THEN CONCAT('Unity: Gameplay Systems ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
            WHEN @SubName = 'Unreal Engine' THEN CONCAT('Unreal: Blueprints, C++ & Optimization ', @FormatLabel, @Suffix)
            WHEN @SubName = 'Game Design' THEN CONCAT('Game Design: Systems, Balance & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = '2D Game Development' THEN CONCAT('2D Games: Physics, Animation & ', @FocusLabel, ' ', @FormatLabel, @Suffix)
            WHEN @SubName = 'VR/AR Development' THEN CONCAT('VR/AR: Interaction, Performance & Comfort ', @FormatLabel, @Suffix)

            ELSE CONCAT(@SubName, ': ', @FormatLabel, ' (', @LevelLabel, ')', @Suffix)
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
