USE PachadataFormation;

SELECT so.Nom as NomSociete, c.Titre, c.Prenom, c.Nom, c.Telephone, s.DateDebut, sl.Titre,
	(SELECT COUNT(*) 
	FROM Inscription.Inscription i2 
	WHERE i2.InscriptionId <> i.InscriptionId 
	AND i2.SessionId = s.SessionId
	AND i2.DateAnnulation IS NULL) as AutresInscriptions
FROM Contact.Contact c
JOIN Contact.Societe so ON c.SocieteId = so.SocieteId
JOIN Contact.Adresse a ON c.AdressePostaleId = a.AdresseId
JOIN Reference.ville v ON v.VilleId = a.VilleId
JOIN Inscription.Inscription i ON c.ContactId = i.ContactId
JOIN Stage.Session s ON i.SessionId = s.SessionId
JOIN Stage.StageLangue sl ON s.StageId = sl.StageId AND s.LangueCd = sl.LangueCd
WHERE v.CodeRegion = 23
AND sl.Titre LIKE 'SQL Server%'
AND YEAR(s.DateDebut) = 2011
AND MONTH(s.DateDebut) = 10