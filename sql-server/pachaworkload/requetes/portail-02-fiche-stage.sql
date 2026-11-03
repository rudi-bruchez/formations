-- appli: portail
-- poids: 40
-- param: @StageId int, @LangueCd char = SELECT StageId, LangueCd FROM Stage.StageLangue
-- Fiche d'un stage dans une langue. Recherche par clé primaire, la requête la plus fréquente du site.
SELECT s.StageId, s.Code, s.Duree, sl.Titre, sl.SousTitre, sl.PhraseSynthese,
       sl.PreRequis, sl.ProfilParticipants, sl.Objectifs, d.Libelle AS Domaine, c.Libelle AS Categorie
FROM Stage.Stage AS s
JOIN Stage.StageLangue AS sl ON sl.StageId = s.StageId
JOIN Stage.Domaine AS d ON d.DomaineCd = s.Domaine
JOIN Stage.Categorie AS c ON c.CategorieCd = s.Categorie
WHERE s.StageId = @StageId AND sl.LangueCd = @LangueCd;
