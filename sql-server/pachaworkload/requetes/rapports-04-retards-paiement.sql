-- appli: rapports
-- poids: 1
-- Factures échues et non soldées au 18 octobre 2026 (la procédure garde un OPTION (HASH JOIN)).
EXEC Rapport.RetardsDePaiement @ADate = '20261018';
