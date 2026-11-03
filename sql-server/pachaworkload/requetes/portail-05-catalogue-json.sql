-- appli: portail
-- poids: 2
-- param: @LangueCd char = SELECT LangueCd FROM Stage.Langue
-- Export du catalogue complet en JSON pour l'application mobile.
EXEC Stage.CatalogueJson @LangueCd = @LangueCd;
