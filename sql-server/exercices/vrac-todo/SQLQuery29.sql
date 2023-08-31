SELECT c.ContactId, Nom, Prenom,
	--RANK() OVER (ORDER BY Nom, Prenom),
	--RANK() OVER (ORDER BY Prenom, Nom),
	ROW_NUMBER() OVER (PARTITION BY LEFT(Nom, 1) ORDER BY Nom, Prenom)
FROM Contact.Contact c
--ORDER BY c.ContactId


SELECT YEAR(DateFacture), MAX(f.MontantHT)
FROM Inscription.Facture f
GROUP BY YEAR(DateFacture)

SELECT 
	YEAR(f.DateFacture) AS Annee, 
	MONTH(f.DateFacture) AS Mois,
	SUM(f.MontantHT),
	-- CA de l'année en cours
	SUM(SUM(f.MontantHT)) OVER (
		PARTITION BY YEAR(f.DateFacture)
		) AS CA_Annuel
FROM Inscription.Facture f
WHERE f.DateFacture IS NOT NULL
GROUP BY YEAR(f.DateFacture), MONTH(f.DateFacture)
ORDER BY Annee, Mois

