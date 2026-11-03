-- appli: rapports
-- poids: 2
-- param: @Annee int = SELECT DISTINCT YEAR(DateDebut) FROM Stage.Session
-- WHERE YEAR(DateDebut) = @Annee : prédicat non SARGable, lecture complète de Session.
EXEC Demo.SessionsParAnnee_Lente @Annee = @Annee;
