-- appli: rapports
-- poids: 2
-- param: @Annee int = SELECT DISTINCT YEAR(DateDebut) FROM Stage.Session
EXEC Rapport.RemplissageSessions @Annee = @Annee;
