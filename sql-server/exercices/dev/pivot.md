# PIVOT

```sql
SELECT [2004], [2005], [2006]
FROM
(
SELECT 
    YEAR(DateFacture) as Annee, 
    MontantHT as CA
FROM Inscription.Facture
WHERE DateFacture > '20000101'
) t
PIVOT
(
    SUM(CA)
    FOR Annee IN ([2004], [2005], [2006])
) as pt
```