-- appli: backoffice
-- poids: 2
-- ecriture: oui
-- param: @InscriptionId int = SELECT i.InscriptionId FROM Inscription.Inscription AS i JOIN Stage.Session AS se ON se.SessionId = i.SessionId WHERE se.DateDebut > '20261025' AND i.DateAnnulation IS NULL AND se.Statut IN ('OUVERTE','CONFIRMEE','PLANIFIEE') AND NOT EXISTS (SELECT 1 FROM Elearning.Progression AS p WHERE p.InscriptionId = i.InscriptionId) AND NOT EXISTS (SELECT 1 FROM Contact.Contact AS c JOIN Contact.Societe AS so ON so.SocieteId = c.SocieteId WHERE c.ContactId = i.ContactId AND so.FacturationAvantInscription = 1)
-- Annulation d'une inscription ; promeut le premier de la liste d'attente.
-- Une inscription déjà annulée par un autre thread sort en erreur 50112 : attendu.
EXEC Inscription.AnnulerInscription @InscriptionId = @InscriptionId, @DateAnnulation = '20261018';
