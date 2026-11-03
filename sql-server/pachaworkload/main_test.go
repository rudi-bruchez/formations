package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	mssql "github.com/microsoft/go-mssqldb"
)

func TestLireRequete(t *testing.T) {
	f := filepath.Join(t.TempDir(), "essai.sql")
	src := "-- appli: backoffice\n-- poids: 7\n-- ecriture: oui\n-- mode: adhoc\n" +
		"-- param: @A int, @B varchar = SELECT 1, 'x'\n-- un commentaire libre\nSELECT @A, @B;\n"
	if err := os.WriteFile(f, []byte(src), 0o644); err != nil {
		t.Fatal(err)
	}
	r, err := lireRequete(f)
	if err != nil {
		t.Fatal(err)
	}
	if r.nom != "essai" || r.appli != "backoffice" || r.poids != 7 || !r.ecriture || !r.adhoc {
		t.Fatalf("en-tête mal lu : %+v", r)
	}
	if len(r.groupes) != 1 || len(r.groupes[0].params) != 2 || r.groupes[0].params[1] != (param{"@B", "varchar"}) || r.groupes[0].requete != "SELECT 1, 'x'" {
		t.Fatalf("paramètres mal lus : %+v", r.groupes)
	}
	if r.corps != "-- un commentaire libre\nSELECT @A, @B;" {
		t.Fatalf("corps : %q", r.corps)
	}
}

func TestEnTexte(t *testing.T) {
	vals := map[string]any{"@Nom": mssql.VarCharMax("O'Neil"), "@NomVille": "Évry", "@Id": int32(3)}
	got := enTexte("WHERE Nom = @Nom AND Ville = @NomVille AND Id = @Id", vals)
	want := "WHERE Nom = 'O''Neil' AND Ville = N'Évry' AND Id = 3"
	if got != want {
		t.Fatalf("\n got %s\nwant %s", got, want)
	}
}

func TestPoste(t *testing.T) {
	cas := []struct {
		appli string
		w, n  int
		want  string
	}{
		{"backoffice", 0, 0, ""},               // sans -postes, le vrai nom de la machine
		{"backoffice", 13, 20, "PC-BUREAU-14"}, // un poste par thread tant qu'il y en a
		{"backoffice", 13, 5, "PC-BUREAU-04"},  // les threads se partagent les postes
		{"portail", 13, 20, "SRV-WEB-02"},      // plafonné à quatre serveurs web
		{"rapports", 7, 20, "SRV-RAPPORTS-01"},
		{"autre", 1, 3, "POSTE-AUTRE-02"},
	}
	for _, c := range cas {
		if got := poste(c.appli, c.w, c.n); got != c.want {
			t.Errorf("poste(%q, %d, %d) = %q, attendu %q", c.appli, c.w, c.n, got, c.want)
		}
	}
}

func TestLireCibles(t *testing.T) {
	f := filepath.Join(t.TempDir(), "cibles.txt")
	src := "# salle 3\n\npc01:1433\npc02:1433 PachaCopie\n  # commentaire indenté\n"
	if err := os.WriteFile(f, []byte(src), 0o644); err != nil {
		t.Fatal(err)
	}
	cs, err := lireCibles(f, "PachaDataFormation")
	if err != nil {
		t.Fatal(err)
	}
	want := []cible{{"pc01:1433", "PachaDataFormation"}, {"pc02:1433", "PachaCopie"}}
	if len(cs) != len(want) || cs[0] != want[0] || cs[1] != want[1] {
		t.Fatalf("got %v, want %v", cs, want)
	}
	if _, err := lireCibles(f, ""); err == nil { // pc01 sans base, et pas de -base
		t.Fatal("une cible sans base doit être refusée")
	}
	os.WriteFile(f, []byte("pc01:1433 base trop\n"), 0o644)
	if _, err := lireCibles(f, "x"); err == nil {
		t.Fatal("une ligne à trois champs doit être refusée")
	}
}

func TestChaineConnexion(t *testing.T) {
	t.Setenv("SQLCMDPASSWORD", "secret")
	t.Setenv("WORKLOAD_USER", "")
	sqlAuth, err := chaineConnexion("srv:1433", "PachaDataFormation", "portail", "", false)
	if err != nil || !strings.HasPrefix(sqlAuth, "sqlserver://sa:secret@srv:1433") {
		t.Fatalf("authentification SQL : %q, %v", sqlAuth, err)
	}
	t.Setenv("SQLCMDPASSWORD", "")
	t.Setenv("MSSQL_SA_PASSWORD", "")
	win, err := chaineConnexion("srv:1433", "PachaDataFormation", "portail", "", true)
	if err != nil || !strings.HasPrefix(win, "sqlserver://srv:1433") || strings.Contains(win, "@") {
		t.Fatalf("authentification Windows : %q, %v", win, err)
	}
	if _, err := chaineConnexion("srv:1433", "b", "a", "", false); err == nil {
		t.Fatal("mot de passe absent accepté")
	}
}
