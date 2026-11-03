-- appli: marketing
-- poids: 6
-- param: @CampagneId int = SELECT CampagneId FROM Marketing.Campagne
-- Taux d'ouverture et de clic d'une campagne. Les campagnes vont de quelques envois
-- à des centaines de milliers : un plan en recherche dans ix_Envoi_CampagneId ne vaut que pour les petites
-- (sur 2022, le plan répartiteur PSP en garde plusieurs variantes ; à voir dans le Query Store).
SELECT c.Nom, c.DateEnvoi, COUNT(*) AS Envois,
       SUM(CAST(e.Ouvert AS int)) AS Ouverts, SUM(CAST(e.Clic AS int)) AS Clics
FROM Marketing.Campagne AS c
JOIN Marketing.Envoi AS e ON e.CampagneId = c.CampagneId
WHERE c.CampagneId = @CampagneId
GROUP BY c.Nom, c.DateEnvoi;
