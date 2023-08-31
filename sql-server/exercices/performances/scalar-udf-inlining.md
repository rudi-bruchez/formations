# Inlining Scalar UDFs

## Problem

USE [PachaDataFormation]
GO
/****** Object:  UserDefinedFunction [Contact].[GetNbInscriptions]    Script Date: 08/11/2022 10:16:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [Contact].[GetNbInscriptions](@ContactId int)
RETURNS BIGINT
AS BEGIN
	RETURN (SELECT COUNT(*) FROM Inscription.Inscription 
	WHERE ContactId = @ContactId);
END;


```sql	
USE PachaDataFormation;
GO

SELECT *, Contact.GetNbInscriptions(ContactId) 
FROM Contact.Contact;
```


