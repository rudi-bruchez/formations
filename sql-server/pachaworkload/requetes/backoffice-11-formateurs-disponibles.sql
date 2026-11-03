-- appli: backoffice
-- poids: 4
-- param: @DomaineCd char, @LangueCd char = SELECT DISTINCT fd.DomaineCd, fl.LangueCd FROM Formateur.FormateurDomaine AS fd JOIN Formateur.FormateurLangue AS fl ON fl.FormateurId = fd.FormateurId
-- param: @Jour date = SELECT DISTINCT DateDebut FROM Stage.Session WHERE DateDebut > '20261018'
-- Formateurs du domaine et de la langue, libres à cette date (pas déjà sur une session qui la couvre).
SELECT f.FormateurId, c.Prenom, c.Nom, tf.TarifJournalier
FROM Formateur.Formateur AS f
JOIN Contact.Contact AS c ON c.ContactId = f.ContactId
JOIN Formateur.FormateurDomaine AS fd ON fd.FormateurId = f.FormateurId AND fd.DomaineCd = @DomaineCd
JOIN Formateur.FormateurLangue AS fl ON fl.FormateurId = f.FormateurId AND fl.LangueCd = @LangueCd
OUTER APPLY (SELECT TOP (1) t.TarifJournalier FROM Formateur.TarifFormateur AS t
             WHERE t.FormateurId = f.FormateurId AND t.DateDebut <= @Jour ORDER BY t.DateDebut DESC) AS tf
WHERE f.NePasContacter = 0
  AND NOT EXISTS (SELECT 1 FROM Stage.Session AS se
                  WHERE se.FormateurId = f.FormateurId
                    AND @Jour >= se.DateDebut AND @Jour < DATEADD(day, se.Duree, se.DateDebut));
