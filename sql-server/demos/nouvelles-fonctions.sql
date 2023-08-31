SELECT 
	-- je veux remplacer les é et les a
	REPLACE(
		REPLACE(Nom, 'é', 'e'),
		'à', 'a'
		) AS Nom,
	TRANSLATE(Nom, 'éàè', 'eae')
FROM Contact.Contact



SELECT CONCAT_WS('--', 'Bonjour', Nom, Prenom)
FROM Contact.Contact c;
