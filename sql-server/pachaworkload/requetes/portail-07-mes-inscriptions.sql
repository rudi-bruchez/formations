-- appli: portail
-- poids: 20
-- param: @ContactId int = SELECT DISTINCT ContactId FROM Inscription.Inscription WHERE ContactId IS NOT NULL
-- Espace stagiaire : ses inscriptions. Aucun index sur Inscription.ContactId :
-- lecture complète des 151 000 inscriptions, candidat évident pour un index manquant.
SELECT i.InscriptionId, se.DateDebut, sl.Titre, i.DateAnnulation, i.ListeAttente, i.Present
FROM Inscription.Inscription AS i
JOIN Stage.Session AS se ON se.SessionId = i.SessionId
JOIN Stage.StageLangue AS sl ON sl.StageId = se.StageId AND sl.LangueCd = se.LangueCd
WHERE i.ContactId = @ContactId
ORDER BY se.DateDebut DESC;
