-- appli: backoffice
-- poids: 5
-- param: @SessionId int = SELECT DISTINCT SessionId FROM Inscription.Inscription WHERE ListeAttente = 1
-- La liste d'attente d'une session, dans l'ordre d'arrivée.
SELECT i.InscriptionId, i.DateCreation, c.Prenom, c.Nom, c.Email
FROM Inscription.Inscription AS i
JOIN Contact.Contact AS c ON c.ContactId = i.ContactId
WHERE i.SessionId = @SessionId AND i.ListeAttente = 1 AND i.DateAnnulation IS NULL
ORDER BY i.DateCreation;
