-- appli: elearning
-- poids: 30
-- param: @InscriptionId int = SELECT DISTINCT InscriptionId FROM Elearning.Progression
-- Tableau de bord du stagiaire : avancement de chaque module. Recherche par clé (InscriptionId, ModuleId).
SELECT m.Ordre, m.Titre, m.Nature, m.DureeMinutes, p.Statut, p.Avancement, p.MeilleurScore, p.DerniereActivite
FROM Elearning.Progression AS p
JOIN Elearning.Module AS m ON m.ModuleId = p.ModuleId
WHERE p.InscriptionId = @InscriptionId
ORDER BY m.Ordre;
