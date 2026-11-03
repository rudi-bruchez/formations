-- appli: elearning
-- poids: 3
-- param: @Decalage bigint = SELECT TOP (200) n.Nombre * 1000 FROM Outils.Nombre AS n ORDER BY n.Nombre
-- Journal d'activité paginé par OFFSET : plus la page est loin, plus la lecture est longue.
-- La version par clé est Demo.ActivitesPage_Corrigee.
EXEC Demo.ActivitesPage_Lente @Decalage = @Decalage, @Taille = 50;
