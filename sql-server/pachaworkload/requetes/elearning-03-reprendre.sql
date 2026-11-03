-- appli: elearning
-- poids: 2
-- param: @ContactId int = SELECT DISTINCT ContactId FROM Elearning.Progression AS p JOIN Inscription.Inscription AS i ON i.InscriptionId = p.InscriptionId
-- « Reprendre là où vous en étiez » : la dernière activité du stagiaire.
-- Elearning.Activite est un tas de 7,8 millions de lignes sans index sur ContactId :
-- chaque appel lit toute la table. La requête la plus chère du workload, à poids faible.
SELECT TOP (1) a.DateHeure, a.ModuleId, a.Etape, a.TypeEvenementCd
FROM Elearning.Activite AS a
WHERE a.ContactId = @ContactId
ORDER BY a.DateHeure DESC;
