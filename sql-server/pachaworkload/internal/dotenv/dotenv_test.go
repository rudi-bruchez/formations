package dotenv

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParse(t *testing.T) {
	input := `# commentaire
export FOO=bar

KEY="quoted value"
OTHER='single'
PLAIN=val
`
	got, err := Parse(strings.NewReader(input))
	if err != nil {
		t.Fatalf("Parse: %v", err)
	}
	cases := map[string]string{
		"FOO":   "bar",
		"KEY":   "quoted value",
		"OTHER": "single",
		"PLAIN": "val",
	}
	for k, want := range cases {
		if got[k] != want {
			t.Errorf("got[%q] = %q, want %q", k, got[k], want)
		}
	}
	if len(got) != len(cases) {
		t.Errorf("got %d entrées, want %d : %v", len(got), len(cases), got)
	}
}

func TestParseErrorNoEquals(t *testing.T) {
	_, err := Parse(strings.NewReader("NOEQUALS\n"))
	if err == nil {
		t.Fatal("attendu une erreur pour ligne sans '='")
	}
}

func TestLoadDoesNotOverride(t *testing.T) {
	// Prépare le fichier .env temporaire
	dir := t.TempDir()
	path := filepath.Join(dir, "test.env")
	if err := os.WriteFile(path, []byte("YT_TEST_KEY=fromfile\nNEW_KEY_DOTENV=created\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	// La variable d'env réelle doit l'emporter
	t.Setenv("YT_TEST_KEY", "fromenv")

	if err := Load(path); err != nil {
		t.Fatalf("Load: %v", err)
	}

	if got := os.Getenv("YT_TEST_KEY"); got != "fromenv" {
		t.Errorf("YT_TEST_KEY = %q, want %q (env doit l'emporter sur .env)", got, "fromenv")
	}
	if got := os.Getenv("NEW_KEY_DOTENV"); got != "created" {
		t.Errorf("NEW_KEY_DOTENV = %q, want %q (clé nouvelle doit être définie)", got, "created")
	}
}

func TestLoadMissingFileNoError(t *testing.T) {
	err := Load(filepath.Join(t.TempDir(), "nope.env"))
	if err != nil {
		t.Fatalf("Load sur fichier absent : attendu nil, got %v", err)
	}
}

func TestLoadFilesPriority(t *testing.T) {
	d := t.TempDir()
	a := filepath.Join(d, "a.env")
	b := filepath.Join(d, "b.env")
	if err := os.WriteFile(a, []byte("SYLLOGE_TEST_A=one\nSYLLOGE_TEST_B=first\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(b, []byte("SYLLOGE_TEST_B=second\nSYLLOGE_TEST_C=three\n"), 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SYLLOGE_TEST_A", "real")
	if err := LoadFiles(a, b); err != nil {
		t.Fatal(err)
	}
	for k, want := range map[string]string{"SYLLOGE_TEST_A": "real", "SYLLOGE_TEST_B": "second", "SYLLOGE_TEST_C": "three"} {
		if got := os.Getenv(k); got != want {
			t.Errorf("%s=%q, want %q", k, got, want)
		}
	}
	bad := filepath.Join(d, "bad.env")
	if err := os.WriteFile(bad, []byte("PAS_DE_SIGNE_EGAL\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := LoadFiles(a, bad); err == nil || !strings.Contains(err.Error(), "bad.env") {
		t.Fatalf("erreur de parsing non rendue : %v", err)
	}
}
