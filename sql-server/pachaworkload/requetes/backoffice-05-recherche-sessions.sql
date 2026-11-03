-- appli: backoffice
-- poids: 6
-- param: @StageId int, @LangueCd char = SELECT StageId, LangueCd FROM Stage.StageLangue
-- param: @DateDebut date = SELECT DISTINCT DATEFROMPARTS(YEAR(DateDebut), 1, 1) FROM Stage.Session
-- Écran de recherche multicritère, écrit avec (Col = @p OR @p IS NULL) :
-- un seul plan pour toutes les combinaisons. La version corrigée est Demo.RechercheSessions_Corrigee.
EXEC Demo.RechercheSessions_Lente @StageId = @StageId, @LangueCd = @LangueCd, @DateDebut = @DateDebut;
