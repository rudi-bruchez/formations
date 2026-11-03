-- appli: marketing
-- poids: 3
-- param: @CampagneId int = SELECT CampagneId FROM Marketing.Campagne
-- Rapport des envois d'une campagne par la procédure existante (distribution asymétrique, PSP).
EXEC Rapport.EnvoisParCampagne @CampagneId = @CampagneId;
