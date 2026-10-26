USE [master]
GO
/****** Object:  Database [PachadataTraining]    Script Date: 16/02/2026 22:11:59 ******/
IF DB_ID(N'PachadataTraining') IS NULL
BEGIN
    CREATE DATABASE [PachadataTraining]
     CONTAINMENT = NONE
     ON  PRIMARY
    ( NAME = N'PachaDataFormation', FILENAME = N'/var/opt/mssql/data/PachaDataTraining.mdf' , SIZE = 168256KB , MAXSIZE = UNLIMITED, FILEGROWTH = 20480KB )
     LOG ON
    ( NAME = N'PachaDataFormation_log', FILENAME = N'/var/opt/mssql/data/PachaDataTraining.LDF' , SIZE = 138496KB , MAXSIZE = 2048GB , FILEGROWTH = 20480KB )
     WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
END
GO
ALTER DATABASE [PachadataTraining] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [PachadataTraining].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [PachadataTraining] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [PachadataTraining] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [PachadataTraining] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [PachadataTraining] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [PachadataTraining] SET ARITHABORT OFF 
GO
ALTER DATABASE [PachadataTraining] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [PachadataTraining] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [PachadataTraining] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [PachadataTraining] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [PachadataTraining] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [PachadataTraining] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [PachadataTraining] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [PachadataTraining] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [PachadataTraining] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [PachadataTraining] SET  DISABLE_BROKER 
GO
ALTER DATABASE [PachadataTraining] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [PachadataTraining] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [PachadataTraining] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [PachadataTraining] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [PachadataTraining] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [PachadataTraining] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [PachadataTraining] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [PachadataTraining] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [PachadataTraining] SET  MULTI_USER 
GO
ALTER DATABASE [PachadataTraining] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [PachadataTraining] SET DB_CHAINING OFF 
GO
ALTER DATABASE [PachadataTraining] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [PachadataTraining] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
ALTER DATABASE [PachadataTraining] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [PachadataTraining] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [PachadataTraining] SET OPTIMIZED_LOCKING = OFF 
GO
EXEC sys.sp_db_vardecimal_storage_format N'PachadataTraining', N'ON'
GO
ALTER DATABASE [PachadataTraining] SET QUERY_STORE = OFF
GO
USE [PachadataTraining]
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = ON;
GO
USE [PachadataTraining]
GO
/****** Object:  Schema [Contact]    Script Date: 16/02/2026 22:11:59 ******/
IF SCHEMA_ID(N'Contact') IS NULL EXEC(N'CREATE SCHEMA [Contact]')
GO
/****** Object:  Schema [Course]    Script Date: 16/02/2026 22:11:59 ******/
IF SCHEMA_ID(N'Course') IS NULL EXEC(N'CREATE SCHEMA [Course]')
GO
/****** Object:  Schema [Enrollment]    Script Date: 16/02/2026 22:11:59 ******/
IF SCHEMA_ID(N'Enrollment') IS NULL EXEC(N'CREATE SCHEMA [Enrollment]')
GO
/****** Object:  Schema [Reference]    Script Date: 16/02/2026 22:11:59 ******/
IF SCHEMA_ID(N'Reference') IS NULL EXEC(N'CREATE SCHEMA [Reference]')
GO
/****** Object:  Schema [Tools]    Script Date: 16/02/2026 22:11:59 ******/
IF SCHEMA_ID(N'Tools') IS NULL EXEC(N'CREATE SCHEMA [Tools]')
GO
/****** Object:  Schema [Trainer]    Script Date: 16/02/2026 22:11:59 ******/
IF SCHEMA_ID(N'Trainer') IS NULL EXEC(N'CREATE SCHEMA [Trainer]')
GO
/****** Object:  UserDefinedFunction [dbo].[fnDateTable]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Function [dbo].[fnDateTable]
(
  @StartDate datetime,
  @EndDate datetime,
  @DayPart char(5) -- support 'day','month','year','hour', default 'day'
)
Returns @Result Table
(
  [Date] datetime
)
As
Begin
  Declare @CurrentDate datetime
  Set @CurrentDate=@StartDate
  While @CurrentDate<=@EndDate
  Begin
    Insert Into @Result Values (@CurrentDate)
    Select @CurrentDate=
    Case
    When @DayPart='year' Then DateAdd(yy,1,@CurrentDate)
    When @DayPart='month' Then DateAdd(mm,1,@CurrentDate)
    When @DayPart='hour' Then DateAdd(hh,1,@CurrentDate)
    Else
      DateAdd(dd,1,@CurrentDate)
    End
  End
  Return
End
GO
/****** Object:  UserDefinedFunction [Enrollment].[fGetNombreDeSessions]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [Enrollment].[fGetNombreDeSessions](@ContactId int)
RETURNS bigint
AS BEGIN
	RETURN (
		SELECT COUNT(*)
		FROM Enrollment.Enrollment
		WHERE ContactId = @ContactId
	)
END
GO
/****** Object:  Table [Enrollment].[Enrollment]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Enrollment].[Enrollment](
	[InscriptionId] [int] IDENTITY(1,1) NOT NULL,
	[SessionId] [int] NOT NULL,
	[DecideurInscriptionId] [int] NULL,
	[ContactId] [int] NULL,
	[DateAnnulation] [date] NULL,
	[Remise] [tinyint] NOT NULL,
	[Present] [bit] NOT NULL,
	[DateCreation] [smalldatetime] NOT NULL,
	[ReferenceCommande] [varchar](100) NULL,
	[ConventionEnvoyee] [bit] NOT NULL,
	[ConvocationEnvoyee] [bit] NOT NULL,
	[ListeAttente] [bit] NOT NULL,
	[FeuilleEmargement] [varchar](1000) NULL,
 CONSTRAINT [pk_Inscription] PRIMARY KEY CLUSTERED 
(
	[InscriptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contact].[Contact]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[Contact](
	[ContactId] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](3) NULL,
	[LastName] [varchar](50) NOT NULL,
	[FirstName] [varchar](50) NULL,
	[Email] [varchar](150) NULL,
	[Phone] [varchar](15) NULL,
	[Fax] [varchar](15) NULL,
	[Gender] [varchar](1) NULL,
	[Mobile] [varchar](15) NULL,
	[AddressId] [int] NOT NULL,
	[CompanyId] [int] NULL,
	[OldLastName] [varchar](50) NULL,
 CONSTRAINT [pk_Contact] PRIMARY KEY CLUSTERED 
(
	[ContactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Course].[Session]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Course].[Session](
	[SessionId] [int] IDENTITY(1,1) NOT NULL,
	[CourseId] [int] NOT NULL,
	[LanguageCd] [char](2) NOT NULL,
	[RoomId] [int] NULL,
	[StartDate] [date] NOT NULL,
	[Price] [decimal](8, 2) NULL,
	[Note] [tinyint] NULL,
	[Status] [char](10) NULL,
	[CreationDate] [date] NOT NULL,
	[Duration] [tinyint] NULL,
	[IntraEntrerprise] [bit] NOT NULL,
	[Comments] [varchar](1500) NULL,
	[TrainerId] [int] NULL,
 CONSTRAINT [pk_SessionStage] PRIMARY KEY CLUSTERED 
(
	[SessionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_SessionStage_CodeDateLieu] UNIQUE NONCLUSTERED 
(
	[StartDate] ASC,
	[RoomId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Contact].[contactAggregate]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [Contact].[contactAggregate]
AS
SELECT c.ContactId 
      ,c.Title
	  ,c.LastName
	  ,c.FirstName
	  ,LOWER(c.Email) AS Email
	  ,s.SessionId
	  ,s.CourseId
	  ,s.LanguageCd
	  ,s.RoomId
	  ,s.StartDate
FROM Contact.Contact c
LEFT JOIN Enrollment.Enrollment e 
	ON c.ContactId = e.ContactId
LEFT JOIN Course.Session s 
	ON e.SessionId = s.SessionId;
GO
/****** Object:  Table [Contact].[Address]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[Address](
	[AddressId] [int] IDENTITY(1,1) NOT NULL,
	[CityId] [int] NULL,
	[Address1] [varchar](50) NOT NULL,
	[Address2] [varchar](50) NULL,
	[Valid] [bit] NOT NULL,
 CONSTRAINT [pk_Adresse] PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Reference].[City]    Script Date: 16/02/2026 22:11:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[City](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[RegionId] [int] NULL,
	[Name] [varchar](255) NULL,
	[ZipCode] [varchar](10) NULL,
	[CodeINSEE] [float] NULL,
	[CodeRegion] [float] NULL,
	[Latitude] [decimal](6, 2) NULL,
	[Longitude] [varchar](255) NULL,
	[Eloignement] [varchar](255) NULL,
	[PointGeographique] [geography] NULL,
 CONSTRAINT [PK_VILLE] PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Course].[CourseLanguage]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Course].[CourseLanguage](
	[StageId] [int] NOT NULL,
	[LangueCd] [char](2) NOT NULL,
	[Titre] [varchar](200) NOT NULL,
	[SousTitre] [varchar](200) NULL,
	[PhraseSynthese] [varchar](500) NULL,
	[PreRequis] [varchar](1000) NULL,
	[ProfilParticipants] [varchar](500) NULL,
	[Objectifs] [varchar](1000) NULL,
 CONSTRAINT [pk_StageLangue] PRIMARY KEY CLUSTERED 
(
	[StageId] ASC,
	[LangueCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Reference].[TrainingRoom]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[TrainingRoom](
	[SalleFormationId] [int] IDENTITY(1,1) NOT NULL,
	[LieuFormationId] [int] NOT NULL,
	[Places] [tinyint] NOT NULL,
	[Nom] [varchar](20) NULL,
	[Numero] [varchar](3) NULL,
	[Couloir] [char](1) NULL,
	[Direction] [char](1) NULL,
	[Etage] [tinyint] NULL,
 CONSTRAINT [PK_salles] PRIMARY KEY CLUSTERED 
(
	[SalleFormationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[ExportJson]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [dbo].[ExportJson]
AS
SELECT TOP 10000 
	CAST(InscriptionId as varchar(10)) as id,
	DateCreation as creationDate,
	c.FirstName as [contact.firstName],
	c.LastName as [contact.lastName],
	c.Email as [contact.email],
	a.Address1 as [contact.address],
	ci.ZipCode as [contact.zipCode],
	ci.Name as [contact.city],
	'France' as [contact.country],
	s.SessionId as [session.sessionId],
	s.CourseId as [session.courseId],
	s.startDate as [session.startDate],
	s.Price as [session.price],
	cl.Titre as [session.course],
	CONCAT_WS(' ', t.FirstName, t.LastName) as [session.trainer],
	CONCAT(REPLACE(tr.Nom, 'SALLE', 'Room'), ' (Floor ', Etage, ')') as [session.room]
FROM Enrollment.Enrollment e
JOIN Contact.Contact c ON e.ContactId = c.ContactId
JOIN Contact.Address a ON a.AddressId = c.AddressId
JOIN Reference.City ci ON a.CityId = ci.CityId
JOIN Course.Session s ON e.SessionId = s.SessionId
JOIN Course.CourseLanguage cl ON s.CourseId = cl.StageId AND s.LanguageCd = cl.LangueCd
JOIN Contact.Contact t ON s.TrainerId = t.ContactId
JOIN Reference.TrainingRoom tr ON s.RoomId = tr.SalleFormationId
ORDER BY id
GO
/****** Object:  Table [Contact].[AddressType]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[AddressType](
	[TypeAdresseId] [tinyint] NOT NULL,
	[Libelle] [varchar](20) NOT NULL,
 CONSTRAINT [pk_TypeAdresse] PRIMARY KEY NONCLUSTERED 
(
	[TypeAdresseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_TypeAdresse_Libelle] UNIQUE NONCLUSTERED 
(
	[Libelle] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contact].[Company]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[Company](
	[CompanyId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](60) NOT NULL,
	[VATNumber] [varchar](30) NULL,
	[TypeRelance] [smallint] NOT NULL,
	[FacturationAvantInscription] [bit] NOT NULL,
	[Telephone2] [varchar](30) NULL,
	[Telephone1] [varchar](30) NULL,
	[Remise] [tinyint] NOT NULL,
 CONSTRAINT [pk_Societe] PRIMARY KEY CLUSTERED 
(
	[CompanyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_Societe_Nom] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contact].[CompanyAddress]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[CompanyAddress](
	[CompanyId] [int] NOT NULL,
	[AdressId] [int] NOT NULL,
	[TypeAdresse] [char](1) NOT NULL,
 CONSTRAINT [pk_SocieteAdresse] PRIMARY KEY CLUSTERED 
(
	[CompanyId] ASC,
	[AdressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contact].[ContactToImport]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[ContactToImport](
	[FirstName] [varchar](50) NOT NULL,
	[LastName] [varchar](50) NOT NULL,
	[Address] [varchar](50) NOT NULL,
	[ZipCode] [varchar](20) NOT NULL,
	[City] [varchar](255) NOT NULL,
	[Phone] [varchar](50) NULL,
	[Email] [varchar](100) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [Contact].[Manager]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[Manager](
	[DecideurId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NULL,
	[DateAnnulation] [date] NULL,
	[EnvoisParEmail] [int] NOT NULL,
	[EnvoisParCourrier] [int] NOT NULL,
 CONSTRAINT [pk_Decideur] PRIMARY KEY CLUSTERED 
(
	[DecideurId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contact].[Title]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contact].[Title](
	[TitleCd] [char](8) NOT NULL,
	[Libelle] [varchar](32) NOT NULL,
 CONSTRAINT [pk_Titre] PRIMARY KEY NONCLUSTERED 
(
	[TitleCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_Titre_Libelle] UNIQUE NONCLUSTERED 
(
	[Libelle] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Course].[Course]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Course].[Course](
	[CourseId] [int] IDENTITY(1,1) NOT NULL,
	[Category] [char](2) NOT NULL,
	[Domain] [char](2) NOT NULL,
	[CreationDate] [smalldatetime] NOT NULL,
	[AnnulationDate] [date] NULL,
	[Comments] [varchar](2000) NULL,
	[Duration] [tinyint] NOT NULL,
	[MaxNbParticipants] [tinyint] NOT NULL,
 CONSTRAINT [pk_Stage] PRIMARY KEY CLUSTERED 
(
	[CourseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Course].[Language]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Course].[Language](
	[LangueCd] [char](2) NOT NULL,
	[NomLocal] [varchar](50) NOT NULL,
	[NomFrancais] [varchar](50) NOT NULL,
 CONSTRAINT [pk_Langue] PRIMARY KEY CLUSTERED 
(
	[LangueCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_Langue_NomFrancais] UNIQUE NONCLUSTERED 
(
	[NomFrancais] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_Langue_NomLocal] UNIQUE NONCLUSTERED 
(
	[NomLocal] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Enrollment].[AdressOnEnrollment]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Enrollment].[AdressOnEnrollment](
	[InscriptionId] [int] NOT NULL,
	[AdresseId] [int] NOT NULL,
	[Invoicing] [bit] NOT NULL,
	[Convention] [bit] NOT NULL,
	[ConventionLetter] [bit] NOT NULL,
	[Certificate] [bit] NOT NULL,
	[Copy] [bit] NOT NULL,
 CONSTRAINT [pk_AdresseSurInscription] PRIMARY KEY CLUSTERED 
(
	[InscriptionId] ASC,
	[AdresseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Enrollment].[Appraisal]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Enrollment].[Appraisal](
	[EvaluationId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NULL,
	[TauxSatisfaction] [int] NOT NULL,
	[Interet] [int] NULL,
	[TempsAccorde] [int] NULL,
	[Exercices] [int] NULL,
	[Support] [int] NULL,
	[Animation] [int] NULL,
	[Equilibre] [int] NULL,
	[Observations] [varchar](2048) NULL,
	[Ajouter] [varchar](2048) NULL,
	[Supprimer] [varchar](2048) NULL,
	[Attentes] [int] NULL,
	[Organisation] [int] NULL,
	[Accueil] [int] NULL,
	[Confort] [int] NULL,
	[ConnaissancePacha] [int] NULL,
	[Nouveautes] [int] NULL,
	[Recommandation] [int] NULL,
	[Jour1Interet] [int] NULL,
	[Jour2Interet] [int] NULL,
	[Jour3Interet] [int] NULL,
	[Jour4Interet] [int] NULL,
	[Jour5Interet] [int] NULL,
	[Jour1Pedagogie] [int] NULL,
	[Jour2Pedagogie] [int] NULL,
	[Jour3Pedagogie] [int] NULL,
	[Jour4Pedagogie] [int] NULL,
	[Jour5Pedagogie] [int] NULL,
	[Formation] [varchar](512) NULL,
	[DateEvaluation] [datetime] NOT NULL,
	[TypeSaisie] [bit] NULL,
	[Annulee] [bit] NULL,
	[Moyenne] [decimal](4, 2) NULL,
	[MiseAJour] [bit] NOT NULL,
	[DateMiseAJour] [datetime] NULL,
 CONSTRAINT [pk_Evaluations] PRIMARY KEY CLUSTERED 
(
	[EvaluationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Enrollment].[EnrollmentInvoice]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Enrollment].[EnrollmentInvoice](
	[InscriptionId] [int] NOT NULL,
	[FactureCd] [varchar](50) NOT NULL,
 CONSTRAINT [pk_InscriptionFacture] PRIMARY KEY CLUSTERED 
(
	[InscriptionId] ASC,
	[FactureCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Enrollment].[Invoice]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Enrollment].[Invoice](
	[InvoiceId] [varchar](50) NOT NULL,
	[CodeRemise] [char](2) NULL,
	[Remise] [decimal](10, 7) NULL,
	[CreationDate] [smalldatetime] NOT NULL,
	[InvoiceDate] [date] NULL,
	[Relance] [tinyint] NOT NULL,
	[DateRelance] [date] NULL,
	[PART] [decimal](7, 4) NULL,
	[ReferenceCommande] [varchar](100) NULL,
	[MontantHT] [decimal](7, 2) NOT NULL,
	[MontantTTC] [decimal](7, 2) NOT NULL,
	[TauxTVA] [decimal](5, 2) NOT NULL,
 CONSTRAINT [pk_Invoice] PRIMARY KEY CLUSTERED 
(
	[InvoiceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Enrollment].[InvoiceFollowUp]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Enrollment].[InvoiceFollowUp](
	[SuiviFactureId] [int] IDENTITY(1,1) NOT NULL,
	[FactureCd] [varchar](50) NULL,
	[DatePaiement] [date] NOT NULL,
	[TypePaiement] [char](1) NOT NULL,
	[NoChequeBanque] [varchar](50) NULL,
	[NoBordereau] [varchar](10) NULL,
	[Montant] [decimal](8, 2) NOT NULL,
 CONSTRAINT [pk_SuiviFacture] PRIMARY KEY CLUSTERED 
(
	[SuiviFactureId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Reference].[Country]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[Country](
	[PaysCD] [char](3) NOT NULL,
	[FrenchName] [varchar](50) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Code2] [char](2) NOT NULL,
	[Capital] [varchar](50) NULL,
 CONSTRAINT [pk_Pays] PRIMARY KEY NONCLUSTERED 
(
	[PaysCD] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_Pays_Nom] UNIQUE NONCLUSTERED 
(
	[FrenchName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Reference].[PaymentMode]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[PaymentMode](
	[ModePaiementCd] [char](8) NOT NULL,
	[Libelle] [varchar](64) NOT NULL,
 CONSTRAINT [pk_ModePaiement] PRIMARY KEY NONCLUSTERED 
(
	[ModePaiementCd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_ModePaiement_Libelle] UNIQUE NONCLUSTERED 
(
	[Libelle] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Reference].[Region]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[Region](
	[RegionId] [int] IDENTITY(1,1) NOT NULL,
	[PaysCD] [char](3) NOT NULL,
	[TypeRegion] [varchar](20) NULL,
	[CodeRegion] [varchar](10) NULL,
	[Nom] [varchar](50) NOT NULL,
	[CodeChefLieu] [char](3) NULL,
	[NomChefLieu] [varchar](50) NULL,
	[XChefLieu] [smallint] NULL,
	[YChefLieu] [smallint] NULL,
	[XCentroide] [smallint] NULL,
	[YCentroide] [smallint] NULL,
	[CodeDepartement] [char](2) NULL,
	[NomDepartement] [varchar](50) NULL,
	[geog_GADM_FRA2] [geography] NULL,
	[geometrie] [geometry] NULL,
	[DepartementVariantes] [xml] NULL,
 CONSTRAINT [pk_Region] PRIMARY KEY NONCLUSTERED 
(
	[RegionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Reference].[TrainingPlace]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[TrainingPlace](
	[LieuFormationId] [int] IDENTITY(1,1) NOT NULL,
	[Nom] [varchar](30) NULL,
	[Adresse1] [varchar](40) NULL,
	[Adresse2] [varchar](40) NULL,
	[CodePostal] [varchar](7) NULL,
	[Ville] [varchar](20) NULL,
	[Metro] [varchar](30) NULL,
	[Telephone] [varchar](25) NULL,
	[Fax] [varchar](25) NULL,
	[PlanAcces] [varchar](255) NULL,
	[NomContact] [varchar](50) NULL,
	[EmailContact] [varchar](200) NULL,
	[EstCentrePacha] [bit] NOT NULL,
 CONSTRAINT [PK_AdressesFormation] PRIMARY KEY CLUSTERED 
(
	[LieuFormationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Reference].[VAT]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Reference].[VAT](
	[DateDebut] [date] NOT NULL,
	[DateFin] [date] NULL,
	[TAUX1] [decimal](5, 2) NOT NULL,
	[TAUX2] [decimal](5, 2) NULL,
 CONSTRAINT [pk_TauxTVA] PRIMARY KEY CLUSTERED 
(
	[DateDebut] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Tools].[TallyNumber]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Tools].[TallyNumber](
	[nombre] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Trainer].[Rate]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Trainer].[Rate](
	[TarifFormateurId] [int] IDENTITY(1,1) NOT NULL,
	[FormateurId] [int] NOT NULL,
	[DateDebut] [date] NOT NULL,
	[DateFin] [date] NULL,
	[TarifJournalier] [decimal](6, 2) NOT NULL,
 CONSTRAINT [pk$TarifFormateur] PRIMARY KEY CLUSTERED 
(
	[TarifFormateurId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Trainer].[SpecialRate]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Trainer].[SpecialRate](
	[TarifSpecialId] [int] IDENTITY(1,1) NOT NULL,
	[TarifFormateurId] [int] NOT NULL,
	[RegionId] [tinyint] NULL,
	[StageId] [int] NULL,
	[LangueCd] [char](2) NULL,
	[TarifJournalier] [decimal](6, 2) NOT NULL,
 CONSTRAINT [pk$TarifSpecial] PRIMARY KEY CLUSTERED 
(
	[TarifSpecialId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Trainer].[Trainer]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Trainer].[Trainer](
	[TrainerId] [int] IDENTITY(1,1) NOT NULL,
	[NoSecuriteSociale] [varchar](18) NULL,
	[Statut] [char](1) NULL,
	[Commentaires] [varchar](1000) NULL,
	[NePasContacter] [bit] NOT NULL,
	[CV] [bit] NULL,
	[CreationDate] [date] NOT NULL,
	[CreationUser] [varchar](128) NOT NULL,
	[ContactId] [int] NOT NULL,
	[TrainerCompanyId] [int] NOT NULL,
 CONSTRAINT [pk$Formateur] PRIMARY KEY CLUSTERED 
(
	[TrainerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [uq_Formateur_ContactId] UNIQUE NONCLUSTERED 
(
	[ContactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Trainer].[TrainerCompany]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Trainer].[TrainerCompany](
	[TrainerCompanyId] [int] IDENTITY(1,1) NOT NULL,
	[Nom] [varchar](50) NOT NULL,
	[AdresseFormateurId] [int] NOT NULL,
	[TelephoneSociete] [varchar](30) NULL,
	[TelephoneAdministratif] [varchar](30) NULL,
	[Fax] [varchar](30) NULL,
	[Contact] [varchar](150) NULL,
	[Commentaires] [varchar](1000) NULL,
	[Statut] [char](1) NULL,
	[EmailContact] [varchar](150) NULL,
 CONSTRAINT [pk$SocieteFormateur] PRIMARY KEY CLUSTERED 
(
	[TrainerCompanyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Nom] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [mix_Contact_LastName]    Script Date: 16/02/2026 22:12:00 ******/
CREATE NONCLUSTERED INDEX [mix_Contact_LastName] ON [Contact].[Contact]
(
	[LastName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [plouf]    Script Date: 16/02/2026 22:12:00 ******/
CREATE NONCLUSTERED INDEX [plouf] ON [Enrollment].[Enrollment]
(
	[SessionId] ASC
)
INCLUDE([DecideurInscriptionId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [Contact].[Address] ADD  DEFAULT ((1)) FOR [Valid]
GO
ALTER TABLE [Contact].[Company] ADD  DEFAULT ((0)) FOR [TypeRelance]
GO
ALTER TABLE [Contact].[Company] ADD  DEFAULT ((0)) FOR [FacturationAvantInscription]
GO
ALTER TABLE [Contact].[Company] ADD  DEFAULT ((0)) FOR [Remise]
GO
ALTER TABLE [Contact].[CompanyAddress] ADD  DEFAULT ((0)) FOR [TypeAdresse]
GO
ALTER TABLE [Contact].[Manager] ADD  DEFAULT ((1)) FOR [EnvoisParEmail]
GO
ALTER TABLE [Contact].[Manager] ADD  DEFAULT ((0)) FOR [EnvoisParCourrier]
GO
ALTER TABLE [Course].[Course] ADD  CONSTRAINT [DF__Stage__DateCreat__604834B3]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [Course].[Course] ADD  CONSTRAINT [DF__Stage__Duree__613C58EC]  DEFAULT ((5)) FOR [Duration]
GO
ALTER TABLE [Course].[Course] ADD  CONSTRAINT [DF__Stage__NombreSta__62307D25]  DEFAULT ((0)) FOR [MaxNbParticipants]
GO
ALTER TABLE [Course].[Session] ADD  CONSTRAINT [DF__SessionSt__DateC__468862B0]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [Course].[Session] ADD  CONSTRAINT [DF__SessionSt__Intra__477C86E9]  DEFAULT ((0)) FOR [IntraEntrerprise]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] ADD  DEFAULT ((0)) FOR [Invoicing]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] ADD  DEFAULT ((0)) FOR [Convention]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] ADD  DEFAULT ((0)) FOR [ConventionLetter]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] ADD  DEFAULT ((0)) FOR [Certificate]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] ADD  DEFAULT ((0)) FOR [Copy]
GO
ALTER TABLE [Enrollment].[Appraisal] ADD  DEFAULT ((0)) FOR [TypeSaisie]
GO
ALTER TABLE [Enrollment].[Appraisal] ADD  DEFAULT ((0)) FOR [MiseAJour]
GO
ALTER TABLE [Enrollment].[Enrollment] ADD  CONSTRAINT [DF_Inscription_Remise]  DEFAULT ((0)) FOR [Remise]
GO
ALTER TABLE [Enrollment].[Enrollment] ADD  CONSTRAINT [DF__Inscripti__NonPr__2AE0483B]  DEFAULT ((0)) FOR [Present]
GO
ALTER TABLE [Enrollment].[Enrollment] ADD  CONSTRAINT [DF__Inscripti__DateC__2BD46C74]  DEFAULT (getdate()) FOR [DateCreation]
GO
ALTER TABLE [Enrollment].[Enrollment] ADD  CONSTRAINT [DF_Inscription_ConventionEnvoyee]  DEFAULT ((0)) FOR [ConventionEnvoyee]
GO
ALTER TABLE [Enrollment].[Enrollment] ADD  CONSTRAINT [DF_Inscription_ConvocationEnvoyee]  DEFAULT ((0)) FOR [ConvocationEnvoyee]
GO
ALTER TABLE [Enrollment].[Enrollment] ADD  CONSTRAINT [DF_Inscription_ListeAttente]  DEFAULT ((0)) FOR [ListeAttente]
GO
ALTER TABLE [Enrollment].[Invoice] ADD  CONSTRAINT [DF__Facture__Relance__1F6E958F]  DEFAULT ((0)) FOR [Relance]
GO
ALTER TABLE [Reference].[TrainingPlace] ADD  CONSTRAINT [DF__LieuForma__EstCe__3651FAE7]  DEFAULT ((0)) FOR [EstCentrePacha]
GO
ALTER TABLE [Reference].[TrainingRoom] ADD  CONSTRAINT [DF__SalleForm__Place__40CF895A]  DEFAULT ((12)) FOR [Places]
GO
ALTER TABLE [Trainer].[Trainer] ADD  CONSTRAINT [DF__Formateur__Creat__1F398B65]  DEFAULT (getdate()) FOR [CreationDate]
GO
ALTER TABLE [Trainer].[Trainer] ADD  CONSTRAINT [DF__Formateur__Creat__202DAF9E]  DEFAULT (suser_sname()) FOR [CreationUser]
GO
ALTER TABLE [Trainer].[Trainer] ADD  DEFAULT ((4)) FOR [TrainerCompanyId]
GO
ALTER TABLE [Contact].[Address]  WITH CHECK ADD  CONSTRAINT [FK_ADRESSE_REFERENCE_VILLE] FOREIGN KEY([CityId])
REFERENCES [Reference].[City] ([CityId])
GO
ALTER TABLE [Contact].[Address] CHECK CONSTRAINT [FK_ADRESSE_REFERENCE_VILLE]
GO
ALTER TABLE [Contact].[CompanyAddress]  WITH CHECK ADD  CONSTRAINT [FK_SOCIETEA_REFERENCE_ADRESSE] FOREIGN KEY([AdressId])
REFERENCES [Contact].[Address] ([AddressId])
GO
ALTER TABLE [Contact].[CompanyAddress] CHECK CONSTRAINT [FK_SOCIETEA_REFERENCE_ADRESSE]
GO
ALTER TABLE [Contact].[CompanyAddress]  WITH CHECK ADD  CONSTRAINT [FK_SOCIETEA_REFERENCE_SOCIETE] FOREIGN KEY([CompanyId])
REFERENCES [Contact].[Company] ([CompanyId])
GO
ALTER TABLE [Contact].[CompanyAddress] CHECK CONSTRAINT [FK_SOCIETEA_REFERENCE_SOCIETE]
GO
ALTER TABLE [Contact].[Contact]  WITH CHECK ADD  CONSTRAINT [fk_Contact_EstDans_Societe] FOREIGN KEY([CompanyId])
REFERENCES [Contact].[Company] ([CompanyId])
GO
ALTER TABLE [Contact].[Contact] CHECK CONSTRAINT [fk_Contact_EstDans_Societe]
GO
ALTER TABLE [Contact].[Manager]  WITH CHECK ADD  CONSTRAINT [FK_DECIDEUR_REFERENCE_CONTACT] FOREIGN KEY([ContactId])
REFERENCES [Contact].[Contact] ([ContactId])
GO
ALTER TABLE [Contact].[Manager] CHECK CONSTRAINT [FK_DECIDEUR_REFERENCE_CONTACT]
GO
ALTER TABLE [Course].[CourseLanguage]  WITH CHECK ADD  CONSTRAINT [fk_StageLangue_AUne_Langue] FOREIGN KEY([LangueCd])
REFERENCES [Course].[Language] ([LangueCd])
GO
ALTER TABLE [Course].[CourseLanguage] CHECK CONSTRAINT [fk_StageLangue_AUne_Langue]
GO
ALTER TABLE [Course].[CourseLanguage]  WITH CHECK ADD  CONSTRAINT [fk_StageLangue_EstSurUn_Stage] FOREIGN KEY([StageId])
REFERENCES [Course].[Course] ([CourseId])
GO
ALTER TABLE [Course].[CourseLanguage] CHECK CONSTRAINT [fk_StageLangue_EstSurUn_Stage]
GO
ALTER TABLE [Course].[Session]  WITH CHECK ADD  CONSTRAINT [fk_Session_has_Formateur] FOREIGN KEY([TrainerId])
REFERENCES [Trainer].[Trainer] ([TrainerId])
GO
ALTER TABLE [Course].[Session] CHECK CONSTRAINT [fk_Session_has_Formateur]
GO
ALTER TABLE [Course].[Session]  WITH CHECK ADD  CONSTRAINT [FK_SESSIONS_REFERENCE_LIEUFORM] FOREIGN KEY([RoomId])
REFERENCES [Reference].[TrainingRoom] ([SalleFormationId])
GO
ALTER TABLE [Course].[Session] CHECK CONSTRAINT [FK_SESSIONS_REFERENCE_LIEUFORM]
GO
ALTER TABLE [Course].[Session]  WITH CHECK ADD  CONSTRAINT [fk_SessionStage_AUn_StageLangue] FOREIGN KEY([CourseId], [LanguageCd])
REFERENCES [Course].[CourseLanguage] ([StageId], [LangueCd])
GO
ALTER TABLE [Course].[Session] CHECK CONSTRAINT [fk_SessionStage_AUn_StageLangue]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment]  WITH CHECK ADD  CONSTRAINT [FK_ADRESSES_ADRESSESU_ADRESSE] FOREIGN KEY([AdresseId])
REFERENCES [Contact].[Address] ([AddressId])
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] CHECK CONSTRAINT [FK_ADRESSES_ADRESSESU_ADRESSE]
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment]  WITH CHECK ADD  CONSTRAINT [FK_AdresseSurInscription_References_Inscription] FOREIGN KEY([InscriptionId])
REFERENCES [Enrollment].[Enrollment] ([InscriptionId])
GO
ALTER TABLE [Enrollment].[AdressOnEnrollment] CHECK CONSTRAINT [FK_AdresseSurInscription_References_Inscription]
GO
ALTER TABLE [Enrollment].[Appraisal]  WITH CHECK ADD  CONSTRAINT [FK_EVALUATI_REFERENCE_CONTACT] FOREIGN KEY([ContactId])
REFERENCES [Contact].[Contact] ([ContactId])
GO
ALTER TABLE [Enrollment].[Appraisal] CHECK CONSTRAINT [FK_EVALUATI_REFERENCE_CONTACT]
GO
ALTER TABLE [Enrollment].[Enrollment]  WITH CHECK ADD  CONSTRAINT [FK_INSCRIPT_INSCRIPTI_DECIDEUR] FOREIGN KEY([DecideurInscriptionId])
REFERENCES [Contact].[Manager] ([DecideurId])
GO
ALTER TABLE [Enrollment].[Enrollment] CHECK CONSTRAINT [FK_INSCRIPT_INSCRIPTI_DECIDEUR]
GO
ALTER TABLE [Enrollment].[Enrollment]  WITH CHECK ADD  CONSTRAINT [FK_INSCRIPT_REFERENCE_CONTACT] FOREIGN KEY([ContactId])
REFERENCES [Contact].[Contact] ([ContactId])
GO
ALTER TABLE [Enrollment].[Enrollment] CHECK CONSTRAINT [FK_INSCRIPT_REFERENCE_CONTACT]
GO
ALTER TABLE [Enrollment].[EnrollmentInvoice]  WITH CHECK ADD  CONSTRAINT [FK_INSCRIPT_FACTUREIN_INSCRIPT] FOREIGN KEY([InscriptionId])
REFERENCES [Enrollment].[Enrollment] ([InscriptionId])
GO
ALTER TABLE [Enrollment].[EnrollmentInvoice] CHECK CONSTRAINT [FK_INSCRIPT_FACTUREIN_INSCRIPT]
GO
ALTER TABLE [Enrollment].[EnrollmentInvoice]  WITH CHECK ADD  CONSTRAINT [FK_INSCRIPT_INSCRIPTI_FACTURE] FOREIGN KEY([FactureCd])
REFERENCES [Enrollment].[Invoice] ([InvoiceId])
GO
ALTER TABLE [Enrollment].[EnrollmentInvoice] CHECK CONSTRAINT [FK_INSCRIPT_INSCRIPTI_FACTURE]
GO
ALTER TABLE [Enrollment].[InvoiceFollowUp]  WITH CHECK ADD  CONSTRAINT [FK_SUIVIFAC_PAIEMENTF_FACTURE] FOREIGN KEY([FactureCd])
REFERENCES [Enrollment].[Invoice] ([InvoiceId])
GO
ALTER TABLE [Enrollment].[InvoiceFollowUp] CHECK CONSTRAINT [FK_SUIVIFAC_PAIEMENTF_FACTURE]
GO
ALTER TABLE [Reference].[Region]  WITH CHECK ADD  CONSTRAINT [FK_REGION_REFERENCE_PAYS] FOREIGN KEY([PaysCD])
REFERENCES [Reference].[Country] ([PaysCD])
GO
ALTER TABLE [Reference].[Region] CHECK CONSTRAINT [FK_REGION_REFERENCE_PAYS]
GO
ALTER TABLE [Reference].[TrainingRoom]  WITH CHECK ADD  CONSTRAINT [FK_SALLEFOR_REFERENCE_LIEUFORM] FOREIGN KEY([LieuFormationId])
REFERENCES [Reference].[TrainingPlace] ([LieuFormationId])
GO
ALTER TABLE [Reference].[TrainingRoom] CHECK CONSTRAINT [FK_SALLEFOR_REFERENCE_LIEUFORM]
GO
ALTER TABLE [Trainer].[Rate]  WITH CHECK ADD  CONSTRAINT [fk$TarifFormateur$Reference$Formateur] FOREIGN KEY([FormateurId])
REFERENCES [Trainer].[Trainer] ([TrainerId])
GO
ALTER TABLE [Trainer].[Rate] CHECK CONSTRAINT [fk$TarifFormateur$Reference$Formateur]
GO
ALTER TABLE [Trainer].[SpecialRate]  WITH CHECK ADD  CONSTRAINT [fk$TarifSpecial$Reference$TarifFormateur] FOREIGN KEY([TarifFormateurId])
REFERENCES [Trainer].[Rate] ([TarifFormateurId])
GO
ALTER TABLE [Trainer].[SpecialRate] CHECK CONSTRAINT [fk$TarifSpecial$Reference$TarifFormateur]
GO
ALTER TABLE [Trainer].[Trainer]  WITH CHECK ADD  CONSTRAINT [fk$Formateur$has$SocieteFormateur] FOREIGN KEY([TrainerCompanyId])
REFERENCES [Trainer].[TrainerCompany] ([TrainerCompanyId])
GO
ALTER TABLE [Trainer].[Trainer] CHECK CONSTRAINT [fk$Formateur$has$SocieteFormateur]
GO
ALTER TABLE [Trainer].[Trainer]  WITH CHECK ADD  CONSTRAINT [fk_Formateur_est_ContactId] FOREIGN KEY([ContactId])
REFERENCES [Contact].[Contact] ([ContactId])
GO
ALTER TABLE [Trainer].[Trainer] CHECK CONSTRAINT [fk_Formateur_est_ContactId]
GO
ALTER TABLE [Trainer].[TrainerCompany]  WITH CHECK ADD  CONSTRAINT [fk$SocieteFormateur$a$AdresseFormateur] FOREIGN KEY([AdresseFormateurId])
REFERENCES [Contact].[Address] ([AddressId])
GO
ALTER TABLE [Trainer].[TrainerCompany] CHECK CONSTRAINT [fk$SocieteFormateur$a$AdresseFormateur]
GO
ALTER TABLE [Contact].[CompanyAddress]  WITH CHECK ADD  CONSTRAINT [CHK_SocieteAdresse_typeAdresse] CHECK  (([TypeAdresse]='C' OR [TypeAdresse]='F' OR [TypeAdresse]='P'))
GO
ALTER TABLE [Contact].[CompanyAddress] CHECK CONSTRAINT [CHK_SocieteAdresse_typeAdresse]
GO
ALTER TABLE [Course].[Course]  WITH CHECK ADD  CONSTRAINT [chk_Course_Category] CHECK  (([Category]='SE' OR [Category]='PC'))
GO
ALTER TABLE [Course].[Course] CHECK CONSTRAINT [chk_Course_Category]
GO
ALTER TABLE [Reference].[TrainingRoom]  WITH CHECK ADD  CONSTRAINT [CK_salles_Couloir] CHECK  (([Couloir]='B' OR [Couloir]='A' OR [Couloir] IS NULL))
GO
ALTER TABLE [Reference].[TrainingRoom] CHECK CONSTRAINT [CK_salles_Couloir]
GO
ALTER TABLE [Reference].[TrainingRoom]  WITH CHECK ADD  CONSTRAINT [CK_salles_Direction] CHECK  (([Direction]='G' OR [Direction]='D' OR [Direction] IS NULL))
GO
ALTER TABLE [Reference].[TrainingRoom] CHECK CONSTRAINT [CK_salles_Direction]
GO
ALTER TABLE [Trainer].[TrainerCompany]  WITH CHECK ADD CHECK  ((len([Nom])>(0)))
GO
/****** Object:  StoredProcedure [Contact].[AjouteContact]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
peut-on faire mieux ?
1/ ce code est-il correct ?
2/ faites mieux pour SQL Server 2005
3/ faites mieux pour SQL Server 2008 et suivants
4/ améliorez la procédure autant que possible
*/

CREATE PROCEDURE [Contact].[AjouteContact]
    @Titre varchar(3) = 'M.',
    @Nom varchar(50),
    @Prenom varchar(50),
    @Email varchar(150),
    @Telephone varchar(15) = NULL,
    @Telecopie varchar(15) = NULL,
    @Sexe varchar(1) = NULL,
    @Portable varchar(15) = NULL
AS BEGIN
	SET NOCOUNT ON

	DECLARE @id int
	DECLARE @table TABLE (ContactId int)

    UPDATE Contact.Contact
    SET Title = @Titre,
        LastName = @Nom,
        FirstName = @Prenom,
        Phone =
			CASE 
				WHEN @Telephone = '' THEN Phone
				ELSE @Telephone 
			END,
        Fax = @Telecopie,
        Gender = @Sexe,
        Mobile = @Portable
    OUTPUT inserted.ContactId INTO @table
	WHERE Email = @Email
	

	IF @@ROWCOUNT = 0 BEGIN
        INSERT INTO Contact.Contact
		    (Title, LastName, FirstName, Email, Phone, Fax, Gender, Mobile)
        OUTPUT inserted.ContactId INTO @table
        VALUES
            (@Titre, @Nom, @Prenom, @Email, @Telephone, @Telecopie, @Sexe, @Portable)
	END

    SELECT TOP 1 @id = ContactId
    FROM @table;

    RETURN @id
END
GO
/****** Object:  StoredProcedure [Contact].[GetContact1]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [Contact].[GetContact1]
	@LastName varchar(50)
AS BEGIN

	SELECT *
	FROM Contact.Contact
	WHERE LastName LIKE @LastName;

END;
GO
/****** Object:  StoredProcedure [Contact].[GetContact2]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [Contact].[GetContact2]
	@LastName varchar(50)
AS BEGIN

	SET @LastName = '%' + @LastName + '%';

	SELECT *
	FROM Contact.Contact
	WHERE LastName LIKE @LastName;

END;
GO
/****** Object:  StoredProcedure [Contact].[GetContact3]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [Contact].[GetContact3]
	@LastName varchar(50)
AS BEGIN

	DECLARE @lastname2 varchar(50)
	SET @LastName2 = '%' + @LastName + '%'

	SELECT *
	FROM Contact.Contact
	WHERE LastName LIKE @LastName2;

END;
GO
/****** Object:  StoredProcedure [Contact].[ImportContacts]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Contact].[ImportContacts]
AS BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION;

	DECLARE 
		@FirstName varchar(50),
		@LastName varchar(50),
		@Address varchar(50),
		@ZipCode varchar(20),
		@City varchar(255),
		@Phone varchar(50),
		@Email varchar(100);

	DECLARE 
		@CityId int,
		@AddressId int;

	DECLARE	cur CURSOR FORWARD_ONLY STATIC
	FOR 
		SELECT FirstName, Address, LastName, ZipCode, City, Phone, Email
		FROM Contact.ContactToImport;

	DECLARE @count smallint
	SELECT @count = 1

	OPEN cur
	FETCH NEXT FROM cur INTO @FirstName, @Address, @LastName, @ZipCode, @City, @Phone, @Email;

	WHILE (@@fetch_status <> -1)
	BEGIN
		IF (@@fetch_status <> -2)
		BEGIN
			-- insert the city if needed
			IF NOT EXISTS (
				SELECT *
				FROM Reference.City c
				WHERE c.ZipCode = @ZipCode
				AND c.Name = @City
			)
			BEGIN
				INSERT INTO Reference.City
					(Name, ZipCode)
				VALUES
					(@City, @ZipCode);

				SET @CityId = SCOPE_IDENTITY();
			END ELSE BEGIN
				SELECT @CityId = CityId
				FROM Reference.City c
				WHERE c.ZipCode = @ZipCode
				AND c.Name = @City
			END;

			-- insert the address if needed
			IF NOT EXISTS (
				SELECT *
				FROM Contact.Address a
				WHERE a.Address1 = @Address
				AND a.CityId = @CityId
			)
			BEGIN
				INSERT INTO Contact.Address
					(CityId, Address1)
				VALUES
					(@CityId, @Address);

				SET @AddressId = SCOPE_IDENTITY();
			END ELSE BEGIN
				SELECT @AddressId = AddressId
				FROM Contact.Address a
				WHERE a.Address1 = @Address
				AND a.CityId = @CityId
			END;
			IF NOT EXISTS (
				SELECT *
				FROM Contact.Contact c
				WHERE c.Email = @Email
			)
			BEGIN
				INSERT INTO Contact.Contact 
					(FirstName, AddressId, LastName, Phone, Email)
				VALUES
					(@FirstName, @AddressId, @LastName, @Phone, @Email)
			END 
			DELETE FROM Contact.ContactToImport WHERE Email = @Email;
		END
		FETCH NEXT FROM cur INTO @FirstName, @Address, @LastName, @ZipCode, @City, @Phone, @Email;
		
		PRINT 'imported contact #' + CAST(@count as varchar(10));
		SELECT @count = @count + 1
	END

	CLOSE cur;
	DEALLOCATE cur;

	ROLLBACK TRANSACTION;
END;
GO
/****** Object:  StoredProcedure [Contact].[ImportContacts_New]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [Contact].[ImportContacts_New]
AS BEGIN
	SET NOCOUNT ON;

	BEGIN TRANSACTION;

	INSERT INTO Reference.City
		(Name, ZipCode)
	SELECT City, ZipCode
	FROM Contact.ContactToImport
	EXCEPT
	SELECT Name, ZipCode
	FROM Reference.City;

	INSERT INTO Contact.Address
		(CityId, Address1)
	SELECT CityId, Address
	FROM Contact.ContactToImport AS ct
	JOIN Reference.City AS ci ON ct.ZipCode = ci.ZipCode AND ct.City = ci.Name
	EXCEPT
	SELECT CityId, Address1
	FROM Contact.Address;

	INSERT INTO Contact.Contact 
		(FirstName, AddressId, LastName, Phone, Email)
	SELECT ct.FirstName, AddressId, ct.LastName, ct.Phone, ct.Email
	FROM Contact.ContactToImport AS ct
	JOIN Reference.City AS ci ON ct.ZipCode = ci.ZipCode AND ct.City = ci.Name
	JOIN Contact.Address AS a ON ci.CityId = a.CityId AND ct.Address = a.Address1
	EXCEPT
	SELECT FirstName, AddressId, LastName, Phone, Email
	FROM Contact.Contact;

	ROLLBACK TRANSACTION;
END;
GO
/****** Object:  StoredProcedure [dbo].[GetContact]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContact]
	@Nom varchar(50)
AS BEGIN
	SET NOCOUNT ON;

	SELECT *
	FROM Contact.Contact
	WHERE Nom = @Nom;
END;
GO
/****** Object:  StoredProcedure [dbo].[GetContact_density]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContact_density]
	@Nom varchar(50)
WITH RECOMPILE
AS BEGIN
	SET NOCOUNT ON;

	DECLARE @le_nom varchar(50) = @nom;

	SELECT *
	FROM Contact.Contact
	WHERE Nom = @le_nom;
END;
GO
/****** Object:  StoredProcedure [dbo].[GetContact_recompiled]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetContact_recompiled]
	@Nom varchar(50)
WITH RECOMPILE
AS BEGIN
	SET NOCOUNT ON;

	SELECT *
	FROM Contact.Contact
	WHERE Nom = @Nom;
END;
GO
/****** Object:  StoredProcedure [dbo].[ProcedurePlans]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ProcedurePlans]
AS
SELECT OBJECT_NAME([ps].[object_id], [ps].[database_id]) 
            AS [ProcedureName]
	, [ps].[execution_count] AS [ProcedureExecutes]
	, [qs].[plan_generation_num] AS [VersionOfPlan]
	, [qs].[execution_count] AS [ExecutionsOfCurrentPlan]
	, SUBSTRING ([st].[text], 
		([qs].[statement_start_offset] / 2) + 1, 
	    ((CASE [statement_end_offset] 
			WHEN -1 THEN DATALENGTH ([st].[text]) 
		    ELSE [qs].[statement_end_offset] END 
			- [qs].[statement_start_offset]) / 2) + 1) 
		    AS [StatementText]
    , [qs].[statement_start_offset] AS [offset]
    , [qs].[statement_end_offset] AS [offset_end]
    , [qp].[query_plan] AS [Query Plan XML]
    , [qs].[query_hash] AS [Query Fingerprint]
    , [qs].[query_plan_hash] AS [Query Plan Fingerprint]
FROM [sys].[dm_exec_procedure_stats] AS [ps]
	JOIN [sys].[dm_exec_query_stats] AS [qs]
		ON [ps].[plan_handle] = [qs].[plan_handle]
    CROSS APPLY [sys].[dm_exec_query_plan] 
                        ([qs].[plan_handle]) AS [qp]
	CROSS APPLY [sys].[dm_exec_sql_text] 
                        ([qs].[sql_handle]) AS [st]
WHERE [ps].[database_id] = DB_ID()
	AND OBJECT_NAME([ps].[object_id], [ps].[database_id]) 
		NOT IN (N'ProcedurePlans', N'RecompileEvents')
ORDER BY [ProcedureName]
	, [qs].[statement_start_offset];
GO
/****** Object:  StoredProcedure [dbo].[RecompileEvents]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RecompileEvents]
AS
SET NOCOUNT ON;
SELECT 
       [event].[value]('(event/@name)[1]', 'VARCHAR(50)') 
            AS [EventName]
       
       , DATEADD(hh, 
            DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
            [event].[value]('(event/@timestamp)[1]', 'DATETIME2')) 
            AS [EventTime]
       
       , [event].[value]('(event/data[@name="recompile_cause"]/text)[1]'
            , 'VARCHAR(255)') AS [RecompileCause]

       , OBJECT_NAME ([event].[value]('(event/data[@name="object_id"]/value)[1]'
                , 'INT') 
            , [event].[value]('(event/data[@name="source_database_id"]/value)[1]'
                , 'INT')) AS [ObjectName]

       , [event].[value]('(event/data[@name="offset"]/value)[1]'
            , 'INT') AS [offset]

       , [event].[value]('(event/data[@name="offset_end"]/value)[1]'
            , 'INT') AS [offset_end]

FROM 
     (   SELECT [n].[query]('.') AS [event] 
         FROM 
         ( 
             SELECT CAST([target_data] AS XML) AS [target_data] 
             FROM [sys].[dm_xe_sessions] AS [s]
             JOIN [sys].[dm_xe_session_targets] AS [t] 
                 ON [s].[address] = [t].[event_session_address]
             WHERE [s].[name] = N'XE_Recompiles' 
               AND [t].[target_name] = N'ring_buffer' 
         ) AS [sub] 
         CROSS APPLY [target_data].[nodes]('RingBufferTarget/event') 
            AS [q]([n]) 
     ) AS [tab]; 
GO
/****** Object:  StoredProcedure [dbo].[testProfiler]    Script Date: 16/02/2026 22:12:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exercice 1 : identifiez de quelle partie de cette procédure 
viennent les problèmes de performance, et quantifiez aussi
précisément que possible quels sont les problèmes.

exercice 2 : vous n'avez pas la main sur cette requete et
vous ne voyez que les outils de trace du serveur. Combien
de fois la boucle WHILE est-elle 
*/

CREATE PROCEDURE [dbo].[testProfiler]
AS BEGIN
    DECLARE @formateurs TABLE (id int);
    DECLARE @formateurId int;

    INSERT INTO @formateurs
    SELECT TrainerId FROM Trainer.Trainer;

    WHILE EXISTS (SELECT * FROM @formateurs) BEGIN
        SELECT TOP 1 @formateurId = id FROM @formateurs;

        SELECT s2.*
        FROM Enrollment.Enrollment i1
        JOIN Course.Session s1 ON i1.SessionId = s1.SessionId
        JOIN Course.Session s2 ON s1.CourseId = s2.CourseId AND s1.LanguageCd = s2.LanguageCd AND s1.SessionId <> s2.SessionId
        JOIN Enrollment.Enrollment i2 ON i2.SessionId = s2.SessionId
        WHERE s1.TrainerId = @formateurId
        AND s2.TrainerId <> @formateurId;

        DELETE FROM @formateurs WHERE id = @formateurId
    END
END
GO
USE [master]
GO
ALTER DATABASE [PachadataTraining] SET  READ_WRITE 
GO
