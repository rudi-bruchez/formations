-- appli: backoffice
-- poids: 10
-- param: @FactureCd varchar = SELECT FactureCd FROM Inscription.Facture
-- Une facture, ses lignes et ses règlements : trois lots, trois recherches par clé.
SELECT f.FactureCd, f.DateFacture, f.DateEcheance, f.MontantHT, f.MontantTTC, f.Relance, f.TypeDocument, s.Nom AS Societe
FROM Inscription.Facture AS f
LEFT JOIN Contact.Societe AS s ON s.SocieteId = f.SocieteId
WHERE f.FactureCd = @FactureCd;
SELECT lf.NumeroLigne, lf.TypeLigne, lf.Libelle, lf.Quantite, lf.PrixUnitaire, lf.MontantHT
FROM Inscription.LigneFacture AS lf
WHERE lf.FactureCd = @FactureCd
ORDER BY lf.NumeroLigne;
SELECT sf.DatePaiement, sf.Montant, mp.Libelle
FROM Inscription.SuiviFacture AS sf
JOIN Reference.ModePaiement AS mp ON mp.ModePaiementCd = sf.ModePaiementCd
WHERE sf.FactureCd = @FactureCd;
