# Tally Tables

```sql
SELECT *,
    DATEADD(day, duree - 1, DateDebut) as DateFin,
    d.Jour
FROM Stage.Session s
JOIN Outils.TallyDate d ON d.Jour BETWEEN DateDebut
    AND DATEADD(day, duree - 1, DateDebut)
WHERE SessionId = 40

SELECT *
FROM Contact.Contact

SELECT *
FROM Outils.TallyDate

SELECT *
FROM Contact.Contact c
RIGHT JOIN Outils.Nombre n ON c.ContactId = n.nombre
WHERE c.ContactId IS NULL
```