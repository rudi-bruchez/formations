-- appli: marketing
-- poids: 15
-- ecriture: oui
-- param: @EnvoiId int = SELECT EnvoiId FROM Marketing.Envoi TABLESAMPLE (30000 ROWS)
-- param: @Clic bit = SELECT CAST(0 AS bit) UNION ALL SELECT CAST(0 AS bit) UNION ALL SELECT CAST(1 AS bit)
-- Le pixel de suivi : un courriel est ouvert, parfois cliqué. Mise à jour par clé, très courte.
EXEC Marketing.EnregistrerOuverture @EnvoiId = @EnvoiId, @Clic = @Clic;
