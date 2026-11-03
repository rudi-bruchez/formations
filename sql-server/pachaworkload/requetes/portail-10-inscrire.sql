-- appli: portail
-- poids: 4
-- ecriture: oui
-- param: @SessionId int = SELECT SessionId FROM Stage.Session WHERE DateDebut > '20261018' AND Statut IN ('OUVERTE','CONFIRMEE','PLANIFIEE') AND IntraEntrerprise = 0
-- param: @ContactId int = SELECT c.ContactId FROM Contact.Contact AS c LEFT JOIN Contact.Societe AS s ON s.SocieteId = c.SocieteId WHERE c.DateDeNaissance BETWEEN '19620101' AND '20050101' AND ISNULL(s.FacturationAvantInscription, 0) = 0
-- Inscription en ligne. Transaction courte avec UPDLOCK et HOLDLOCK sur la session :
-- deux inscriptions simultanées à la même session se bloquent un instant.
-- Les refus métier (session pleine, déjà inscrit) sortent en erreurs 5010x : c'est attendu.
EXEC Inscription.InscrireStagiaire @SessionId = @SessionId, @ContactId = @ContactId, @ReferenceCommande = NULL;
