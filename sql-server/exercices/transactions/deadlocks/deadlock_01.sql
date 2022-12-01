BEGIN TRANSACTION

UPDATE Contact.Adresse
SET Adresse1 = 'Place Emmanuel Kant'

UPDATE Contact.Contact
SET Nom = 'Spinoza',
	Prenom = 'Baruch'

ROLLBACK TRANSACTION