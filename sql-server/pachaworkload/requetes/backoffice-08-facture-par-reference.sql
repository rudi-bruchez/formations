-- appli: backoffice
-- poids: 3
-- param: @Ref varchar = SELECT DISTINCT RIGHT(ReferenceCommande, 4) FROM Inscription.Facture WHERE LEN(ReferenceCommande) >= 4
-- Retrouver une facture d'après un morceau du numéro de commande du client : LIKE '%...%'.
-- Ni index ni statistique utile ne sert un joker en tête : lecture complète de Facture.
SELECT TOP (50) f.FactureCd, f.ReferenceCommande, f.DateFacture, f.MontantTTC
FROM Inscription.Facture AS f
WHERE f.ReferenceCommande LIKE '%' + @Ref + '%'
ORDER BY f.DateFacture DESC;
