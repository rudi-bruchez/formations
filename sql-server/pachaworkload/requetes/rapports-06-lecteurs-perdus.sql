-- appli: rapports
-- poids: 1
-- param: @Mois int = SELECT 3 UNION ALL SELECT 6 UNION ALL SELECT 12
-- Fonctions de fenêtrage sur les quatre millions d'envois, de l'ordre de dix secondes : parallélisme, octroi de mémoire.
EXEC Rapport.LecteursPerdus @Mois = @Mois;
