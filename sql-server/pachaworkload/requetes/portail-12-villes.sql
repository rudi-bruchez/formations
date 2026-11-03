-- appli: portail
-- poids: 10
-- param: @Debut varchar = SELECT DISTINCT LEFT(NomVille, 3) FROM Reference.ville WHERE LEN(NomVille) >= 3
-- Autocomplétion de la ville dans le formulaire d'adresse : LIKE 'abc%'.
-- Aucun index sur NomVille : lecture des 35 000 villes à chaque frappe.
SELECT TOP (15) v.VilleId, v.NomVille, v.CodePostal
FROM Reference.ville AS v
WHERE v.NomVille LIKE @Debut + '%'
ORDER BY v.NomVille;
