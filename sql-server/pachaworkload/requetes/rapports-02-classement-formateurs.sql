-- appli: rapports
-- poids: 2
-- param: @Annee int = SELECT DISTINCT YEAR(DateDebut) FROM Stage.Session WHERE DateDebut < '20261018'
EXEC Rapport.ClassementFormateurs @Annee = @Annee;
