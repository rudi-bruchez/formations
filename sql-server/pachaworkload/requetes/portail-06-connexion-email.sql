-- appli: portail
-- poids: 25
-- mode: adhoc
-- param: @Email varchar = SELECT Email FROM Contact.Contact WHERE Email IS NOT NULL
-- Connexion d'un stagiaire par son adresse. Deux défauts voulus :
-- l'application concatène l'adresse dans le texte (un plan par adresse dans le cache,
-- « optimize for ad hoc workloads » et paramétrage forcé à essayer),
-- et aucun index sur Contact.Email (lecture complète de 120 000 lignes à chaque connexion).
SELECT c.ContactId, c.Titre, c.Prenom, c.Nom, c.Email, s.Nom AS Societe
FROM Contact.Contact AS c
LEFT JOIN Contact.Societe AS s ON s.SocieteId = c.SocieteId
WHERE c.Email = @Email;
