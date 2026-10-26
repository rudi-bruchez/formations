USE PachadataTraining;
GO

CREATE TABLE Course.Category (
    CategoryId smallint NOT NULL IDENTITY (1, 1),
    CategoryName NVARCHAR(100) CONSTRAINT uq_CategoryCategoryName UNIQUE, 
    ParentCategoryId smallint NULL, 
    IsActive bit NOT NULL DEFAULT(1),
    CONSTRAINT pk_Category PRIMARY KEY (CategoryId)
)
GO

-- Main categories
INSERT INTO Course.Category 
    (CategoryName, ParentCategoryId, IsActive)
VALUES
    ('Data Engineering', NULL, 1),
    ('Software Development', NULL, 1),
    ('Cloud Computing', NULL, 1),
    ('Data Science', NULL, 1),
    ('DevOps', NULL, 1),
    ('Cybersecurity', NULL, 1),
    ('Artificial Intelligence', NULL, 1),
    ('Web Development', NULL, 1),
    ('Mobile Development', NULL, 1),
    ('Game Development', NULL, 1);
GO

-- Subcategories for Data Engineering
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'SQL Server', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Engineering'
UNION ALL SELECT 'PostgreSQL', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Engineering'
UNION ALL SELECT 'Data Warehousing', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Engineering'
UNION ALL SELECT 'ETL & Data Pipelines', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Engineering'
UNION ALL SELECT 'Big Data', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Engineering';

-- Subcategories for Software Development
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Python', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Software Development'
UNION ALL SELECT 'Java', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Software Development'
UNION ALL SELECT 'C#', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Software Development'
UNION ALL SELECT 'JavaScript', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Software Development'
UNION ALL SELECT 'Go', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Software Development';

-- Subcategories for Cloud Computing
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Azure', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cloud Computing'
UNION ALL SELECT 'AWS', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cloud Computing'
UNION ALL SELECT 'Google Cloud', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cloud Computing'
UNION ALL SELECT 'Cloud Architecture', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cloud Computing'
UNION ALL SELECT 'Serverless Computing', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cloud Computing';

-- Subcategories for Data Science
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Machine Learning', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Science'
UNION ALL SELECT 'Statistical Analysis', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Science'
UNION ALL SELECT 'Data Visualization', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Science'
UNION ALL SELECT 'Business Intelligence', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Science'
UNION ALL SELECT 'Predictive Analytics', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Data Science';

-- Subcategories for DevOps
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'CI/CD Pipelines', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'DevOps'
UNION ALL SELECT 'Containerization', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'DevOps'
UNION ALL SELECT 'Kubernetes', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'DevOps'
UNION ALL SELECT 'Infrastructure as Code', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'DevOps'
UNION ALL SELECT 'Monitoring & Logging', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'DevOps';

-- Subcategories for Cybersecurity
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Network Security', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cybersecurity'
UNION ALL SELECT 'Application Security', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cybersecurity'
UNION ALL SELECT 'Ethical Hacking', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cybersecurity'
UNION ALL SELECT 'Cloud Security', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cybersecurity'
UNION ALL SELECT 'Compliance & Governance', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Cybersecurity';

-- Subcategories for AI
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Natural Language Processing', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Artificial Intelligence'
UNION ALL SELECT 'Computer Vision', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Artificial Intelligence'
UNION ALL SELECT 'Generative AI', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Artificial Intelligence'
UNION ALL SELECT 'AI Ethics', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Artificial Intelligence'
UNION ALL SELECT 'AI in Business', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Artificial Intelligence';

-- Subcategories for Web Development
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Frontend Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Web Development'
UNION ALL SELECT 'Backend Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Web Development'
UNION ALL SELECT 'Full Stack Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Web Development'
UNION ALL SELECT 'Web Performance', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Web Development'
UNION ALL SELECT 'Web Accessibility', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Web Development';

-- Subcategories for Mobile Development
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'iOS Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Mobile Development'
UNION ALL SELECT 'Android Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Mobile Development'
UNION ALL SELECT 'Cross-Platform Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Mobile Development'
UNION ALL SELECT 'Mobile UI/UX', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Mobile Development'
UNION ALL SELECT 'Mobile Security', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Mobile Development';

-- Subcategories for Game Development
INSERT INTO Course.Category (CategoryName, ParentCategoryId, IsActive)
SELECT 'Unity Game Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Game Development'
UNION ALL SELECT 'Unreal Engine', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Game Development'
UNION ALL SELECT 'Game Design', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Game Development'
UNION ALL SELECT '2D Game Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Game Development'
UNION ALL SELECT 'VR/AR Development', CategoryId, 1 FROM Course.Category WHERE CategoryName = 'Game Development';
GO

CREATE TABLE Course.Course
(
	CourseId int IDENTITY(1,1) NOT NULL,
	CategoryId smallint NOT NULL,
    Title NVARCHAR(100) NOT NULL CONSTRAINT uq_Course_CourseName UNIQUE, 
    Description NVARCHAR(2000) NOT NULL,
    DifficultyLevel tinyint NOT NULL DEFAULT (1),
	PublishedDate date NOT NULL,
	RetiredDate date NULL,
	DurationDays tinyint NOT NULL
    CONSTRAINT [pk_Course] PRIMARY KEY CLUSTERED (CourseId),
    CONSTRAINT chk_Course_DifficultyLevel CHECK (DifficultyLevel BETWEEN 1 AND 5)
) WITH (DATA_COMPRESSION = ROW)
GO

