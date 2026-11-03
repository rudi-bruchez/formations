-- appli: portail
-- poids: 3
-- ecriture: oui
-- param: @ContactId int, @Email varchar, @Telephone varchar = SELECT ContactId, Email, ISNULL(Telephone, '0102030405') FROM Contact.Contact WHERE Email IS NOT NULL
-- Le stagiaire met à jour son adresse et son téléphone (mêmes valeurs : la ligne s'écrit quand même).
-- Déclenche atr_Contact_CheckEmail.
EXEC Contact.MettreAJourCoordonnees @ContactId = @ContactId, @Email = @Email, @Telephone = @Telephone;
