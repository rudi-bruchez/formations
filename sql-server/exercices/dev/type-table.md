# Type table et paramètres

```sql  
CREATE TYPE ClientIds AS TABLE (
    id int
)
GO

CREATE PROC GetCLients 
    @ids ClientIds READONLY
AS BEGIN 

    SELECT *
    FROM @ids
END
```