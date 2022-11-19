# Merge

```sql  
MERGE INTO Contact.ProspectUS AS cible
USING (
    SELECT 'Trump' as Nom, 'Madeline' as Prenom,
    'rrr' as Email
) AS source
ON cible.email = source.email
WHEN MATCHED THEN
    UPDATE SET Nom = source.nom
WHEN NOT MATCHED THEN
    INSERT (Nom, Prenom, Email, Adresse)
    VALUES (source.Nom, source.Prenom, source.Email, '');
```