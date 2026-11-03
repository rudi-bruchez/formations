-- appli: rapports
-- poids: 1
-- ecriture: oui
-- Traitement de nuit : relance des factures échues, ligne par ligne dans une boucle.
EXEC Demo.MarquerRelances_Lente @ADate = '20261018';
