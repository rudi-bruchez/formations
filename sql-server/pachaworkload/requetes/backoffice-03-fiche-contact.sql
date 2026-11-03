-- appli: backoffice
-- poids: 15
-- param: @ContactId int = SELECT ContactId FROM Contact.Contact
-- Fiche contact par la procédure existante.
EXEC Contact.GetContactEtNbreInscriptionsParId @ContactId = @ContactId;
