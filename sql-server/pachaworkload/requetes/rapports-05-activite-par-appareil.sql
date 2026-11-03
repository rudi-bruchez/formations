-- appli: rapports
-- poids: 1
-- param: @Debut date, @Fin date = SELECT DISTINCT DATEFROMPARTS(YEAR(DateHeure), MONTH(DateHeure), 1), EOMONTH(DateHeure) FROM Elearning.Activite TABLESAMPLE (2000 ROWS)
-- Agrégat sur les 7,8 millions de lignes du journal e-learning, sur un mois.
EXEC Rapport.ActiviteParAppareil @Debut = @Debut, @Fin = @Fin;
