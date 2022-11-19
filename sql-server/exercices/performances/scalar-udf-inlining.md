# Inlining Scalar UDFs

```sql	
USE PachaDataFormation;
GO

SELECT *, Contact.GetNbInscriptions(ContactId) 
FROM Contact.Contact;
```


