BEGIN TRANSACTION

UPDATE Contact.Contact
SET Nom = 'Spinoza',
	Prenom = 'Baruch'

UPDATE Contact.Adresse
SET Adresse1 = 'Place Emmanuel Kant'

ROLLBACK TRANSACTION