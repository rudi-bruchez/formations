-- appli: marketing
-- poids: 1
-- ecriture: oui
-- param: @Jour date = SELECT DISTINCT DateDebut FROM Stage.Session WHERE DateDebut > '20261018'
-- Création d'une campagne (paramètre de sortie).
DECLARE @CampagneId int;
EXEC Marketing.CreerCampagne @Nom = 'Relance automatique', @DateEnvoi = @Jour, @CampagneId = @CampagneId OUTPUT;
SELECT @CampagneId AS CampagneId;
