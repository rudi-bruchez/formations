-- appli: backoffice
-- poids: 3
-- param: @SocieteId int = SELECT SocieteId FROM Contact.Societe
-- Dernière lettre reçue par chaque contact d'une société, version lente (sous-requête corrélée).
EXEC Demo.DernierEnvoiParContact_Lente @SocieteId = @SocieteId;
