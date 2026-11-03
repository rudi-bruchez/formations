-- appli: backoffice
-- poids: 4
-- ecriture: oui
-- param: @FactureCd varchar, @Montant decimal = SELECT v.FactureCd, CAST(v.Solde / 4 AS decimal(12, 2)) FROM Inscription.vFactureSolde AS v JOIN Inscription.Facture AS f ON f.FactureCd = v.FactureCd WHERE f.TypeDocument = 'F' AND v.Solde > 10
-- param: @ModePaiementCd char = SELECT ModePaiementCd FROM Reference.ModePaiement
-- Saisie d'un règlement partiel (le quart du solde relevé au démarrage).
-- Une facture tirée plusieurs fois finit en trop-perçu, refusé par l'erreur 50136 : c'est attendu.
EXEC Inscription.EnregistrerPaiement @FactureCd = @FactureCd, @Montant = @Montant,
     @ModePaiementCd = @ModePaiementCd, @DatePaiement = '20261018';
