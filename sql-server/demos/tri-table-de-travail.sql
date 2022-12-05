USE tempdb
GO

CREATE TABLE t1 (col1 char(8000));
CREATE TABLE t2 (col2 char(8000));
GO

SELECT *
FROM t1
CROSS JOIN t2
ORDER BY col1
OPTION (HASH JOIN)

/*
-- sort = table de tri
Msg 8618, Niveau 16, État 2, Ligne 8
Le processeur de requêtes n'a pas pu créer un plan de requête, car une 
table de travail est nécessaire et la taille minimale des lignes dépasse 
la valeur maximale autorisée de 8060 octets. En règle générale, une 
table de travail est nécessaire parce que la requête comporte une clause 
GROUP BY ou ORDER BY. Le cas échéant, réduisez le nombre de champs et/ou 
leur taille dans la clause. Utilisez le préfixe (LEFT()) ou le hachage 
(CHECKSUM()) des champs pour le regroupement ou le préfixe pour le tri. 
Notez cependant que cela modifiera le comportement de la requête.

*/