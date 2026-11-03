-- appli: backoffice
-- poids: 1
-- ecriture: oui
-- param: @SessionId int = SELECT se.SessionId FROM Stage.Session AS se WHERE se.Statut = 'TERMINEE' AND se.Prix IS NOT NULL AND se.IntraEntrerprise = 0 AND EXISTS (SELECT 1 FROM Inscription.Inscription AS i WHERE i.SessionId = se.SessionId AND i.DateAnnulation IS NULL AND i.ListeAttente = 0 AND NOT EXISTS (SELECT 1 FROM Inscription.InscriptionFacture AS x WHERE x.InscriptionId = i.InscriptionId))
-- Facturation des inscrits pas encore facturés d'une session terminée : lignes de facture, lien inscription-facture, transaction plus longue.
EXEC Inscription.EmettreFactures @SessionId = @SessionId;
