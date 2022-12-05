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
Msg�8618, Niveau�16, �tat�2, Ligne�8
Le processeur de requ�tes n'a pas pu cr�er un plan de requ�te, car une 
table de travail est n�cessaire et la taille minimale des lignes d�passe 
la valeur maximale autoris�e de 8060�octets. En r�gle g�n�rale, une 
table de travail est n�cessaire parce que la requ�te comporte une clause 
GROUP BY ou ORDER BY. Le cas �ch�ant, r�duisez le nombre de champs et/ou 
leur taille dans la clause. Utilisez le pr�fixe (LEFT()) ou le hachage 
(CHECKSUM()) des champs pour le regroupement ou le pr�fixe pour le tri. 
Notez cependant que cela modifiera le comportement de la requ�te.

*/