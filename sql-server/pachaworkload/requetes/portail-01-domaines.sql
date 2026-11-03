-- appli: portail
-- poids: 20
-- Page d'accueil du site : les domaines et le nombre de stages ouverts dans chacun.
-- Rapide, sans paramètre, toujours le même plan.
SELECT d.DomaineCd, d.Libelle, COUNT(s.StageId) AS NbStages
FROM Stage.Domaine AS d
LEFT JOIN Stage.Stage AS s ON s.Domaine = d.DomaineCd AND s.DateAnnulation IS NULL
GROUP BY d.DomaineCd, d.Libelle
ORDER BY d.Libelle;
