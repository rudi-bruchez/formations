-- appli: portail
-- poids: 35
-- param: @StageId int = SELECT DISTINCT StageId FROM Stage.Session WHERE DateDebut > '20261018'
-- Les prochaines sessions d'un stage, avec le lieu et les places restantes.
-- Index nix_temp_02 (StageId, LangueCd) sur Session et nix_temp_01 (SessionId) sur Inscription.
SELECT se.SessionId, se.DateDebut, se.LangueCd, se.Prix, lf.Ville,
       sa.Places - COUNT(i.InscriptionId) AS PlacesRestantes
FROM Stage.Session AS se
LEFT JOIN Reference.SalleFormation AS sa ON sa.SalleFormationId = se.SalleFormationId
LEFT JOIN Reference.LieuFormation AS lf ON lf.LieuFormationId = sa.LieuFormationId
LEFT JOIN Inscription.Inscription AS i
       ON i.SessionId = se.SessionId AND i.DateAnnulation IS NULL AND i.ListeAttente = 0
WHERE se.StageId = @StageId
  AND se.DateDebut > '20261018'
  AND se.Statut IN ('OUVERTE', 'CONFIRMEE', 'PLANIFIEE')
GROUP BY se.SessionId, se.DateDebut, se.LangueCd, se.Prix, lf.Ville, sa.Places
ORDER BY se.DateDebut;
