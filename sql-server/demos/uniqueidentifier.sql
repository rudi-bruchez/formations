USE [PachaDataFormation]
GO

CREATE TABLE [Contact].[ProspectUS_GUID](
	ProspectUSId UNIQUEIDENTIFIER 
		CONSTRAINT pk_ProspectUS_GUID PRIMARY KEY
		CONSTRAINT df_ProspectUS_GUID DEFAULT (NEWID()),
	[Prenom] [varchar](50) NULL,
	[Nom] [varchar](50) NOT NULL,
	[Adresse] [varchar](50) NOT NULL,
	[CP] [varchar](20) NULL,
	[Ville] [varchar](255) NULL,
	[Tel] [varchar](50) NULL,
	[Email] [varchar](100) NULL
)
GO

USE [PachaDataFormation]
GO

INSERT INTO [Contact].[ProspectUS_GUID]
           ([Prenom]
           ,[Nom]
           ,[Adresse]
           ,[CP]
           ,[Ville]
           ,[Tel]
           ,[Email])
SELECT 
	[Prenom]
	,[Nom]
	,[Adresse]
	,[CP]
	,[Ville]
	,[Tel]
	,[Email]
FROM Contact.ProspectUS;

SELECT TOP (1000) *
FROM [PachaDataFormation].[Contact].[ProspectUS_GUID]
GO


