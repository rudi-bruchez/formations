# Statistiques

## Objectifs

## Exercices

```sql	
SELECT *
FROM Contact.ProspectUS pu
WHERE pu.Nom = 'Diaz'

SELECT *
FROM Contact.Contact c
WHERE c.Nom = 'Diaz'

SELECT *
FROM Contact.Contact c
WHERE c.Nom = 'Simon'

-- UPDATE STATISTICS Contact.Contact

BEGIN TRAN

UPDATE TOP (3000) Contact.Contact
SET Nom = 'Diaz'

ROLLBACK
```