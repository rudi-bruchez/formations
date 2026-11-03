-- appli: backoffice
-- poids: 8
-- param: @Debut date = SELECT DATEFROMPARTS(YEAR(DateDebut), MONTH(DateDebut), 1) FROM Stage.Session GROUP BY YEAR(DateDebut), MONTH(DateDebut)
-- Planning du mois : sessions qui commencent dans le mois, avec remplissage.
-- Prédicat en plage sur DateDebut, qui permet la recherche dans uq_SessionStage_CodeDateLieu.
SELECT se.SessionId, se.DateDebut, sl.Titre, sa.Nom AS Salle, se.Statut,
       COUNT(i.InscriptionId) AS Inscrits
FROM Stage.Session AS se
JOIN Stage.StageLangue AS sl ON sl.StageId = se.StageId AND sl.LangueCd = se.LangueCd
LEFT JOIN Reference.SalleFormation AS sa ON sa.SalleFormationId = se.SalleFormationId
LEFT JOIN Inscription.Inscription AS i ON i.SessionId = se.SessionId AND i.DateAnnulation IS NULL
WHERE se.DateDebut >= @Debut AND se.DateDebut < DATEADD(month, 1, @Debut)
GROUP BY se.SessionId, se.DateDebut, sl.Titre, sa.Nom, se.Statut
ORDER BY se.DateDebut;
