-- appli: backoffice
-- poids: 8
-- param: @SocieteId int = SELECT SocieteId FROM Contact.Societe
-- Les contacts d'une société. Pas d'index sur Contact.SocieteId (la clé étrangère n'en crée pas).
SELECT c.ContactId, c.Titre, c.Prenom, c.Nom, c.Email, c.Telephone
FROM Contact.Contact AS c
WHERE c.SocieteId = @SocieteId
ORDER BY c.Nom, c.Prenom;
