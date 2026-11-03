-- appli: backoffice
-- poids: 5
-- param: @Nom nvarchar = SELECT DISTINCT Nom FROM Contact.Contact
-- La même recherche envoyée par un autre écran, qui passe le nom en nvarchar
-- (le défaut de nombreux pilotes) sur une colonne varchar : CONVERT_IMPLICIT dans le plan.
-- Collation Windows (French_CI_AS) : la recherche dans nix_contact_nom reste possible, par une plage calculée.
SELECT c.ContactId, c.Prenom, c.Nom, c.Email, c.Telephone
FROM Contact.Contact AS c
WHERE c.Nom = @Nom;
