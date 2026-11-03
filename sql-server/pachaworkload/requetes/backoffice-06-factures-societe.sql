-- appli: backoffice
-- poids: 8
-- param: @SocieteId int = SELECT DISTINCT SocieteId FROM Inscription.Facture WHERE SocieteId IS NOT NULL
-- Compte client d'une société : ses factures et leur solde.
SELECT v.FactureCd, v.DateFacture, v.DateEcheance, v.MontantTTC, v.Avoirs, v.Paye, v.Solde, v.Statut
FROM Inscription.vFactureSolde AS v
WHERE v.SocieteId = @SocieteId
ORDER BY v.DateFacture DESC;
