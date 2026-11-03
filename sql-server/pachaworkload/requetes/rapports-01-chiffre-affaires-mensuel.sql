-- appli: rapports
-- poids: 2
-- param: @Debut date, @Fin date = SELECT DISTINCT DATEFROMPARTS(YEAR(DateFacture), 1, 1), DATEFROMPARTS(YEAR(DateFacture), 12, 31) FROM Inscription.Facture WHERE DateFacture IS NOT NULL
EXEC Rapport.ChiffreAffairesMensuel @Debut = @Debut, @Fin = @Fin;
