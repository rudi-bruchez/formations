// Package dotenv charge un fichier .env (lignes KEY=VALUE) dans l'environnement
// du process, sans écraser les variables déjà définies. Aucune dépendance.
package dotenv

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"
)

// Parse lit des lignes KEY=VALUE. Ignore les lignes vides et les commentaires
// (#). Tolère un préfixe "export ". Retire une paire de guillemets simples ou
// doubles entourant la valeur. Une ligne non vide sans '=' est une erreur.
func Parse(r io.Reader) (map[string]string, error) {
	out := map[string]string{}
	sc := bufio.NewScanner(r)
	line := 0
	for sc.Scan() {
		line++
		s := strings.TrimSpace(sc.Text())
		if s == "" || strings.HasPrefix(s, "#") {
			continue
		}
		s = strings.TrimPrefix(s, "export ")
		k, v, ok := strings.Cut(s, "=")
		if !ok {
			return nil, fmt.Errorf("ligne %d : pas de '=' : %q", line, s)
		}
		k = strings.TrimSpace(k)
		if k == "" {
			return nil, fmt.Errorf("ligne %d : clé vide", line)
		}
		out[k] = unquote(strings.TrimSpace(v))
	}
	if err := sc.Err(); err != nil {
		return nil, fmt.Errorf("lecture : %w", err)
	}
	return out, nil
}

func unquote(v string) string {
	if len(v) >= 2 {
		if (v[0] == '"' && v[len(v)-1] == '"') || (v[0] == '\'' && v[len(v)-1] == '\'') {
			return v[1 : len(v)-1]
		}
	}
	return v
}

// Load lit le fichier .env à path et définit dans l'environnement les clés qui
// n'y sont pas déjà (les variables d'environnement réelles l'emportent). Si le
// fichier n'existe pas, Load ne fait rien et ne renvoie pas d'erreur.
func Load(path string) error { return LoadFiles(path) }

// LoadFiles lit les fichiers dans l'ordre ; pour une même clé, le dernier
// fichier l'emporte, et une variable déjà présente dans l'environnement
// l'emporte sur tous. Un fichier absent est ignoré.
func LoadFiles(paths ...string) error {
	vars := map[string]string{}
	for _, path := range paths {
		f, err := os.Open(path)
		if errors.Is(err, os.ErrNotExist) {
			continue
		}
		if err != nil {
			return fmt.Errorf("ouverture de %s : %w", path, err)
		}
		parsed, parseErr := Parse(f)
		closeErr := f.Close()
		if parseErr != nil {
			return fmt.Errorf("parsing de %s : %w", path, parseErr)
		}
		if closeErr != nil {
			return fmt.Errorf("fermeture de %s : %w", path, closeErr)
		}
		for k, v := range parsed {
			vars[k] = v
		}
	}
	for k, v := range vars {
		if _, exists := os.LookupEnv(k); !exists {
			if err := os.Setenv(k, v); err != nil {
				return fmt.Errorf("définition de %s : %w", k, err)
			}
		}
	}
	return nil
}
