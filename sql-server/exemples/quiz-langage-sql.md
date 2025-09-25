# Quiz sur le langage SQL

## Syntaxes

Que pensez-vous de la syntaxe SQL suivante ?

```sql
set @dt_search = coalesce(@dt_start, coalesce(@dt_calc, coalesce(@dt_calc_tax, coalesce(@dt_start_tax, dbo.fn_dateToFloat(getdate())))))
```
