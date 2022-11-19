# Dynamic Data Masking

```sql
CREATE TABLE Contact (
    Nom VARCHAR(50),
    Prenom VARCHAR(50),
    Email VARCHAR(100)
)

-- insertion des données
INSERT INTO Contact (Nom, Prenom, Email)
SELECT TOP 100 Nom, Prenom, Email
FROM PachaDataFormation.Contact.Contact;

CREATE TABLE Contact (
    Nom VARCHAR(50),
    Prenom VARCHAR(50),
    Email VARCHAR(100) MASKED WITH (FUNCTION = 'email()') NULL
)

CREATE USER Normal WITHOUT LOGIN;

GRANT SELECT ON Contact TO Normal
GRANT UNMASK TO Normal
REVOKE UNMASK TO Normal

EXECUTE AS USER = 'Normal'

SELECT CURRENT_USER

SELECT *
FROM Contact c

REVERT

-- ça marche avec les fonctions
SELECT REVERSE(Email)
FROM Contact c
```
