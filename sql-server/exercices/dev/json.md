# JSON

```sql	
SELECT TOP 10 
    c.Nom AS 'Nom',
    c.PRenom AS 'Prenom'
FROM Contact.Contact c
JOIN Inscription.Inscription inscription ON c.ContactId = inscription.ContactId
FOR JSON PATH, ROOT

SELECT *
FROM OPENJSON('{"root":[{"Nom":"Dumont","Prenom":"Marius"},{"Nom":"Charles","Prenom":"Fabien"},{"Nom":"Girard","Prenom":"Louise"},{"Nom":"Ferrer","Prenom":"Yolande"},{"Nom":"Malthus","Prenom":"Irène"},{"Nom":"Thamiry","Prenom":"Ambroise"},{"Nom":"Vagniez-simonneau","Prenom":"Jeanne"},{"Nom":"Perez","Prenom":"Gracianne"},{"Nom":"Gonzalez","Prenom":"Stéphane"},{"Nom":"Buffet","Prenom":"Léontine"}]}',
    '$')

DECLARE @json nvarchar(max) = 
'{ "Produit": 
	{"Nom": "Fromage","Quantite": 1}
}'

--SELECT JSON_VALUE(@json, '$.Produit[0].Quantite')

--SELECT *
--FROM OPENJSON(@json, '$.Produit[0]')

--SELECT JSON_MODIFY(@json, '$.Produit.Quantite', '5')
SELECT JSON_query(@json, '$.Produit')

SELECT TOP 10 Nom, Prenom
FROM Contact.Contact AS c
ORDER BY Nom, Prenom
--FOR XML AUTO, ROOT('contacts'), ELEMENTS
FOR JSON AUTO, ROOT('contacts'), INCLUDE_NULL_VALUES

```	