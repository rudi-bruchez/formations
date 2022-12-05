USE PachaDataFormation;
GO

CREATE VIEW dbo.ContactEtNbInscriptions
AS 
	SELECT c.ContactId, COUNT(InscriptionId) as NbInscriptions
	FROM Contact.Contact c 
	LEFT JOIN Inscription.Inscription i ON i.ContactId = c.ContactId
	GROUP BY c.ContactId;
GO

CREATE PROCEDURE dbo.GetContact
	@ContactId int
AS BEGIN
	SET NOCOUNT ON;

	SELECT c.ContactId, COUNT(InscriptionId) as NbInscriptions
	FROM Contact.Contact c 
	LEFT JOIN Inscription.Inscription i ON i.ContactId = c.ContactId
	WHERE c.ContactId = @ContactId
	GROUP BY c.ContactId;
END;
GO

CREATE SYNONYM dbo.GetOneContact FOR dbo.GetContact;
GO

EXEC dbo.GetOneContact @ContactId = 456;
GO

-- nettoyage
DROP SYNONYM dbo.GetOneContact;
DROP PROCEDURE dbo.GetContact;
DROP VIEW dbo.ContactEtNbInscriptions;