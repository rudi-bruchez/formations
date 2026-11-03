-- appli: portail
-- poids: 10
-- param: @ContactId int = SELECT DISTINCT ContactId FROM Inscription.Facture WHERE ContactId IS NOT NULL
-- Espace stagiaire : ses factures et leur solde, par la vue Inscription.vFactureSolde.
-- Pas d'index sur Facture.ContactId.
SELECT v.FactureCd, v.DateFacture, v.DateEcheance, v.MontantTTC, v.Paye, v.Solde, v.Statut
FROM Inscription.vFactureSolde AS v
WHERE v.ContactId = @ContactId
ORDER BY v.DateFacture DESC;
