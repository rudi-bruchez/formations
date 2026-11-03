-- appli: backoffice
-- poids: 20
-- param: @Nom varchar = SELECT DISTINCT Nom FROM Contact.Contact
-- Recherche d'un contact par nom exact, avec son nombre d'inscriptions.
-- Distribution très inégale : Simon 782 lignes, la plupart des noms 1 ou 2.
-- Le premier nom compilé fixe le plan pour tous (détection de paramètres) :
-- à observer dans le Query Store, plusieurs plans ou des écarts de durée sur un même plan.
SELECT c.ContactId, c.Prenom, c.Nom, c.Email, s.Nom AS Societe,
       (SELECT COUNT(*) FROM Inscription.Inscription AS i WHERE i.ContactId = c.ContactId) AS NbInscriptions
FROM Contact.Contact AS c
LEFT JOIN Contact.Societe AS s ON s.SocieteId = c.SocieteId
WHERE c.Nom = @Nom
ORDER BY c.Prenom;
