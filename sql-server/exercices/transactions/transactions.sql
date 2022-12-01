BEGIN TRANSACTION -- A C I D

DELETE FROM Inscription.InscriptionFacture
WHERE InscriptionId IN (
    SELECT InscriptionId
    FROM Inscription.Inscription i
    WHERE i.ContactId = 4244
  );

DELETE FROM Inscription.Inscription
WHERE ContactId = 4244;

DELETE FROM Contact.Contact
WHERE ContactId = 4244;

ROLLBACK TRANSACTION
