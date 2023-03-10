# Exercice Ledger

Dans la base de données PachadataFormation, on veut créer une table d'évaluation pour permettre aux participants de remplir le questionnaire de satisfaction en fin de formation.

On souhaite se prémunir contre la modification et la suppression, on veut donc créer une table en ajout seul.

On veut également se protéger contre la possibilité qu'aurait un formateur de se connecter dans la base de données et de modifier après coup l'évaluation des participants de ses formations.

```sql
USE [PachaDataFormation]
GO

DROP TABLE IF EXISTS [Inscription].[EvaluationFormation]
GO

CREATE TABLE [Inscription].[EvaluationFormation](
	[EvaluationFormationId] [int] IDENTITY(1,1) NOT NULL,
	[InscriptionId] [int] NOT NULL,
	[Note] [tinyint] NOT NULL 
		CONSTRAINT [CK_EvaluationFormation_Note] CHECK ([Note] BETWEEN 1 AND 5),
	[Commentaire] [varchar](1000) NULL,
	[DateEvaluation] [date] NOT NULL,
 CONSTRAINT [pk_EvaluationFormation] PRIMARY KEY CLUSTERED 
	(EvaluationFormationId)
) WITH (DATA_COMPRESSION = ROW,
	LEDGER = ON (APPEND_ONLY = ON)
)
GO

ALTER TABLE [Inscription].[EvaluationFormation]
ADD  CONSTRAINT [FK_EVAL_INSCRIPT_REFERENCE] FOREIGN KEY([InscriptionId])
REFERENCES [Inscription].[Inscription] ([InscriptionId])
GO

INSERT INTO [Inscription].[EvaluationFormation] (
	[InscriptionId], [Note], [Commentaire], [DateEvaluation])
VALUES 
    (134, 4, 'Très bonne session de formation', '2023-03-08'),
    (2834, 3, 'Session de formation intéressante', '2023-03-08'),
    (3234, 5, 'Excellent formateur, très pédagogique', '2023-03-08'),
    (444, 2, 'Session de formation décevante', '2023-03-08'),
    (8345, 4, 'Bonne ambiance, formateur sympathique', '2023-03-08'),
    (234, 5, 'Formation très pratique, avec beaucoup d''exemples', '2023-03-08'),
    (7512, 3, 'Formateur compétent, mais support de cours peu clair', '2023-03-08'),
    (8834, 4, 'Session de formation utile pour mon travail', '2023-03-08'),
    (9123, 5, 'Formateur à l''écoute, réponse à toutes nos questions', '2023-03-08'),
    (1054, 4, 'Formation intéressante, mais un peu trop théorique', '2023-03-08');

-- test
DELETE FROM [Inscription].[EvaluationFormation]
```