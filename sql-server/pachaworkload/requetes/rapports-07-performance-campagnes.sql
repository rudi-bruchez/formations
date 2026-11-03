-- appli: rapports
-- poids: 1
-- param: @Debut date, @Fin date = SELECT DISTINCT DATEFROMPARTS(YEAR(DateEnvoi), 1, 1), DATEFROMPARTS(YEAR(DateEnvoi), 12, 31) FROM Marketing.Campagne
EXEC Rapport.PerformanceCampagnes @Debut = @Debut, @Fin = @Fin;
