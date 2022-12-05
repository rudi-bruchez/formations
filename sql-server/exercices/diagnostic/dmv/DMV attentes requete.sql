USE PachaDataFormation;
GO

SELECT 
	ContactId,
	COUNT(*) as cnt
FROM Inscription.Inscription WITH (TABLOCKX)
GROUP BY ContactId;

BEGIN TRAN;

UPDATE Contact.Contact
SET Email = REVERSE(Email);
GO 5

ROLLBACK