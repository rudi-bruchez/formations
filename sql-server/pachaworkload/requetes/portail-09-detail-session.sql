-- appli: portail
-- poids: 15
-- param: @SessionId int = SELECT SessionId FROM Stage.Session WHERE DateDebut > '20261018'
-- Détail d'une session avant inscription : salle, lieu, formateur.
SELECT se.SessionId, se.DateDebut, se.Duree, se.Prix, se.Statut, sl.Titre,
       sa.Nom AS Salle, lf.Nom AS Lieu, lf.Adresse1, lf.CodePostal, lf.Ville, lf.Metro,
       c.Prenom + ' ' + c.Nom AS Formateur
FROM Stage.Session AS se
JOIN Stage.StageLangue AS sl ON sl.StageId = se.StageId AND sl.LangueCd = se.LangueCd
LEFT JOIN Reference.SalleFormation AS sa ON sa.SalleFormationId = se.SalleFormationId
LEFT JOIN Reference.LieuFormation AS lf ON lf.LieuFormationId = sa.LieuFormationId
LEFT JOIN Formateur.Formateur AS f ON f.FormateurId = se.FormateurId
LEFT JOIN Contact.Contact AS c ON c.ContactId = f.ContactId
WHERE se.SessionId = @SessionId;
