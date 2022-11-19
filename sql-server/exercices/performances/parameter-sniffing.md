# Parameter sniffing

```sql  
CREATE OR ALTER PROCEDURE GetContact
    @nom varchar(50)
AS BEGIN
    SET NOCOUNT ON;

    DECLARE @nom2 varchar(50) = @nom

    SELECT *
    FROM Contact.Contact
    WHERE (Nom = @nom2 OR @nom2 IS NULL)
    OPTION (RECOMPILE)
END

EXEC GetContact 'simon'
EXEC GetContact 'simon' WITH RECOMPILE
```
