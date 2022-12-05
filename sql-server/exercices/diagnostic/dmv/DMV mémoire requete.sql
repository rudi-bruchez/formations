USE PachaDataFormation;
GO

BEGIN TRAN;

UPDATE Contact.Contact
SET email = REVERSE(Email);

-- attendez avant de faire le rollback

ROLLBACK;