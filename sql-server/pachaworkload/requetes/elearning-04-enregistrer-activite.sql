-- appli: elearning
-- poids: 12
-- ecriture: oui
-- param: @InscriptionId int, @ModuleId int, @ContactId int = SELECT p.InscriptionId, p.ModuleId, i.ContactId FROM Elearning.Progression AS p JOIN Inscription.Inscription AS i ON i.InscriptionId = p.InscriptionId WHERE i.ContactId IS NOT NULL
-- Le lecteur envoie une page lue. ActiviteId n'est pas une identité : l'application
-- calcule MAX + 1 sous UPDLOCK, HOLDLOCK, ce qui sérialise tous les écrivains
-- (attentes LCK_M_* et blocages à observer dès quelques threads).
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @Id bigint = (SELECT ISNULL(MAX(ActiviteId), 0) + 1 FROM Elearning.Activite WITH (UPDLOCK, HOLDLOCK));
INSERT INTO Elearning.Activite (ActiviteId, DateHeure, ContactId, InscriptionId, ModuleId, TypeEvenementCd, Etape, DureeSecondes, Score, Appareil)
VALUES (@Id, SYSDATETIME(), @ContactId, @InscriptionId, @ModuleId, 'PAGE', 1, 30, NULL, 'O');
UPDATE Elearning.Progression
SET TempsPasseSecondes = TempsPasseSecondes + 30, DerniereActivite = SYSDATETIME()
WHERE InscriptionId = @InscriptionId AND ModuleId = @ModuleId;
COMMIT;
