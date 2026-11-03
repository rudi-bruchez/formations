-- appli: elearning
-- poids: 15
-- param: @StageId int = SELECT DISTINCT StageId FROM Elearning.Module
-- Sommaire d'un cours en ligne, par uq_Module_Ordre (StageId, Ordre).
SELECT m.ModuleId, m.Ordre, m.Titre, m.Nature, m.DureeMinutes, m.NbEtapes
FROM Elearning.Module AS m
WHERE m.StageId = @StageId
ORDER BY m.Ordre;
