-- appli: portail
-- poids: 15
-- param: @Mot varchar = SELECT DISTINCT value FROM Stage.StageLangue CROSS APPLY STRING_SPLIT(Titre, ' ') WHERE LEN(value) > 4 AND LangueCd = 'FR'
-- Recherche libre dans le catalogue : LIKE '%mot%', joker en tête.
-- Lecture complète de StageLangue (1 630 lignes) : sans importance ici, c'est la petite table qui le permet.
SELECT TOP (20) sl.StageId, sl.Titre, sl.SousTitre
FROM Stage.StageLangue AS sl
WHERE sl.LangueCd = 'FR'
  AND (sl.Titre LIKE '%' + @Mot + '%' OR sl.Objectifs LIKE '%' + @Mot + '%')
ORDER BY sl.Titre;
