# CTE récursive

```sql	
;WITH cte AS
(
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 10
)
SELECT * FROM cte
```

```sql
WITH cte AS (
    SELECT e.EmployeId, e.Nom, e.ChefId
    FROM Employe e
    WHERE e.EmployeId = 8

    UNION ALL

    -- à changer
    SELECT
    FROM Employe e1
    JOIN cte e2 ON e1.ChefId = e2.EmployeId

)
SELECT *
FROM cte;


WITH cte AS (
    SELECT e.EmployeId, e.Nom, e.ChefId
    FROM Employe e
    WHERE e.EmployeId = 8

    UNION ALL

    SELECT e1.EmployeId, e1.Nom, e1.ChefId
    FROM Employe e1
    JOIN cte e2 ON e1.EmployeId = e2.ChefId

)
SELECT *
FROM cte;
```