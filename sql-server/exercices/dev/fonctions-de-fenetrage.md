# Fonctions de fenêtrage

```sql
SELECT *,
    RANK() OVER (ORDER BY ContactId)
FROM Contact.Contact
WHERE Nom = 'Simon'

;WITH cte AS (
    SELECT 
        RANK() OVER (PARTITION BY YEAR(DateDebut)
            ORDER BY DateDebut) as rn,
        *
    FROM Stage.Session
)
SELECT *
FROM cte
WHERE rn = 1


SELECT 
    YEAR(DateFacture) as Annee, 
    MONTH(DateFacture) as Mois,
    SUM(MontantHT) as CA,
    SUM(MontantHT) / SUM(SUM(MontantHT)) OVER (PARTITION BY YEAR(DateFacture)) * 100,
    SUM(MontantHT) / LAG(SUM(MontantHT)) OVER (ORDER BY YEAR(DateFacture), MONTH(DateFacture)) * 100,
    LAG(SUM(MontantHT)) OVER (ORDER BY YEAR(DateFacture), MONTH(DateFacture)),

    SUM(SUM(MontantHT)) OVER (ORDER BY YEAR(DateFacture), MONTH(DateFacture)
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)

FROM Inscription.Facture
WHERE DateFacture IS NOT NULL
GROUP BY YEAR(DateFacture), MONTH(DateFacture)
ORDER BY Annee, Mois
```
