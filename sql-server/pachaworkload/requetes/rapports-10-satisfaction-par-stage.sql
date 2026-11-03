-- appli: rapports
-- poids: 2
-- param: @Annee int = SELECT DISTINCT YEAR(DateEvaluation) FROM Inscription.Evaluation
-- Note moyenne de satisfaction par stage sur une année : jointure de 856 000 réponses,
-- hachage et agrégat, candidat au parallélisme et à un index couvrant sur Evaluation.
SELECT sl.Titre, COUNT(DISTINCT ev.EvaluationId) AS Evaluations, AVG(CAST(r.Note AS decimal(5, 2))) AS NoteMoyenne
FROM Inscription.Evaluation AS ev
JOIN Inscription.Reponse AS r ON r.EvaluationId = ev.EvaluationId
JOIN Inscription.Inscription AS i ON i.InscriptionId = ev.InscriptionId
JOIN Stage.Session AS se ON se.SessionId = i.SessionId
JOIN Stage.StageLangue AS sl ON sl.StageId = se.StageId AND sl.LangueCd = 'FR'
WHERE ev.DateEvaluation >= DATEFROMPARTS(@Annee, 1, 1) AND ev.DateEvaluation < DATEFROMPARTS(@Annee + 1, 1, 1)
  AND r.Note IS NOT NULL
GROUP BY sl.Titre
ORDER BY NoteMoyenne DESC;
