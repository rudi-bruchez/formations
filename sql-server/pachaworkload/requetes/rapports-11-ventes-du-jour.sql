-- appli: rapports
-- poids: 4
-- mode: adhoc
-- param: @Jour date = SELECT DISTINCT DateFacture FROM Inscription.Facture WHERE DateFacture IS NOT NULL
-- Le widget « ventes du jour » du tableau de bord, écrit par concaténation de la date.
-- Requête sur une seule table : candidate au paramétrage simple ; à vérifier dans le cache
-- (une entrée Prepared paramétrée, ou un plan Adhoc par date).
SELECT COUNT(*) AS Factures, SUM(MontantTTC) AS TotalTTC
FROM Inscription.Facture
WHERE DateFacture = @Jour;
