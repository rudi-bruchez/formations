// pachaworkload rejoue sur PachaDataFormation le trafic d'une application de
// gestion de formation : des requêtes tirées au sort selon leur poids, sur
// plusieurs threads, avec des paramètres pris dans la base elle-même.
//
// Chaque requête est un fichier .sql de requetes/, dont l'en-tête dit le poids,
// l'application qui l'envoie et d'où viennent ses paramètres (voir README.md).
package main

import (
	"context"
	"database/sql"
	"errors"
	"flag"
	"fmt"
	"maps"
	"math/rand/v2"
	"net/url"
	"os"
	"os/signal"
	"path/filepath"
	"regexp"
	"runtime"
	"slices"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	mssql "github.com/microsoft/go-mssqldb"

	"pachaworkload/internal/dotenv"
)

// param est un paramètre déclaré par une ligne « -- param: @A type, @B type = <requête> ».
type param struct {
	nom, typ string
}

// groupe : des paramètres corrélés, tirés ensemble sur une même ligne de leur réserve.
type groupe struct {
	params  []param
	requete string
}

type requete struct {
	nom      string
	appli    string
	poids    int
	ecriture bool
	adhoc    bool // toujours envoyée en texte, littéraux concaténés
	groupes  []groupe
	corps    string
}

var reEntete = regexp.MustCompile(`^--\s*(appli|poids|ecriture|mode|param)\s*:\s*(.*)$`)

func lireRequete(chemin string) (requete, error) {
	b, err := os.ReadFile(chemin)
	if err != nil {
		return requete{}, err
	}
	r := requete{nom: strings.TrimSuffix(filepath.Base(chemin), ".sql"), appli: "portail", poids: 1}
	var corps []string
	for l := range strings.SplitSeq(strings.ReplaceAll(string(b), "\r\n", "\n"), "\n") {
		m := reEntete.FindStringSubmatch(strings.TrimSpace(l))
		if m == nil {
			corps = append(corps, l)
			continue
		}
		v := strings.TrimSpace(m[2])
		switch m[1] {
		case "appli":
			r.appli = v
		case "poids":
			if r.poids, err = strconv.Atoi(v); err != nil || r.poids < 0 {
				return r, fmt.Errorf("%s : poids invalide %q", chemin, v)
			}
		case "ecriture":
			r.ecriture = v == "oui"
		case "mode":
			r.adhoc = v == "adhoc"
		case "param":
			decl, req, ok := strings.Cut(v, "=")
			if !ok {
				return r, fmt.Errorf("%s : param sans requête de réserve : %q", chemin, v)
			}
			g := groupe{requete: strings.TrimSpace(req)}
			for d := range strings.SplitSeq(decl, ",") {
				f := strings.Fields(d)
				if len(f) != 2 || !strings.HasPrefix(f[0], "@") {
					return r, fmt.Errorf("%s : déclaration invalide %q", chemin, d)
				}
				g.params = append(g.params, param{f[0], strings.ToLower(f[1])})
			}
			r.groupes = append(r.groupes, g)
		}
	}
	r.corps = strings.TrimSpace(strings.Join(corps, "\n"))
	return r, nil
}

// valeur convertit ce que rend le pilote dans le type déclaré par l'en-tête.
// Les chaînes partent en varchar(max) ou nvarchar(max), une déclaration constante ;
// avec variable, le pilote déclare varchar(n) à la longueur de la valeur, donc un plan par longueur.
func valeur(v any, typ string, variable bool) any {
	if t, ok := v.(time.Time); ok {
		v = t.Format("20060102")
	}
	if b, ok := v.([]byte); ok { // decimal
		v = string(b)
	}
	s := fmt.Sprint(v)
	switch typ {
	case "int":
		n, _ := strconv.ParseInt(s, 10, 32)
		return int32(n)
	case "bigint":
		n, _ := strconv.ParseInt(s, 10, 64)
		return n
	case "decimal":
		f, _ := strconv.ParseFloat(s, 64)
		return f
	case "bit":
		return s == "true" || s == "1"
	case "nvarchar":
		if variable {
			return s
		}
		return mssql.NVarCharMax(s)
	default: // varchar, char, date : envoyés en varchar, jamais en nvarchar sur une colonne varchar
		if variable {
			return mssql.VarChar(s)
		}
		return mssql.VarCharMax(s)
	}
}

// litteral écrit la valeur telle qu'une application qui concatène l'écrirait.
func litteral(v any) string {
	switch x := v.(type) {
	case mssql.VarChar:
		return "'" + strings.ReplaceAll(string(x), "'", "''") + "'"
	case mssql.VarCharMax:
		return "'" + strings.ReplaceAll(string(x), "'", "''") + "'"
	case string:
		return "N'" + strings.ReplaceAll(x, "'", "''") + "'"
	case mssql.NVarCharMax:
		return "N'" + strings.ReplaceAll(string(x), "'", "''") + "'"
	case bool:
		if x {
			return "1"
		}
		return "0"
	case float64:
		return strconv.FormatFloat(x, 'f', -1, 64)
	default:
		return fmt.Sprint(x)
	}
}

// enTexte remplace chaque @Param par son littéral. Les noms les plus longs passent
// d'abord, pour que @Nom ne mange pas le début de @NomVille.
func enTexte(corps string, vals map[string]any) string {
	noms := make([]string, 0, len(vals))
	for n := range vals {
		noms = append(noms, n)
	}
	sort.Slice(noms, func(i, j int) bool { return len(noms[i]) > len(noms[j]) })
	for _, n := range noms {
		corps = regexp.MustCompile(regexp.QuoteMeta(n)+`\b`).ReplaceAllLiteralString(corps, litteral(vals[n]))
	}
	return corps
}

type reserves struct {
	mu     sync.Mutex
	lignes map[string][][]any
}

func (rs *reserves) charger(ctx context.Context, db *sql.DB, q string, max int) ([][]any, error) {
	rs.mu.Lock()
	defer rs.mu.Unlock()
	if l, ok := rs.lignes[q]; ok {
		return l, nil
	}
	rows, err := db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	cols, _ := rows.Columns()
	var out [][]any
	for rows.Next() && len(out) < max {
		l := make([]any, len(cols))
		p := make([]any, len(cols))
		for i := range l {
			p[i] = &l[i]
		}
		if err := rows.Scan(p...); err != nil {
			return nil, err
		}
		out = append(out, l)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	if len(out) == 0 {
		return nil, errors.New("réserve vide")
	}
	rs.lignes[q] = out
	return out, nil
}

type mesure struct {
	n, erreurs int
	durees     []time.Duration
	derniere   string
}

type stats struct {
	mu sync.Mutex
	m  map[string]*mesure
}

func (s *stats) noter(nom string, d time.Duration, err error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	x := s.m[nom]
	if x == nil {
		x = &mesure{}
		s.m[nom] = x
	}
	x.n++
	x.durees = append(x.durees, d)
	if err != nil {
		x.erreurs++
		x.derniere = err.Error()
	}
}

func (s *stats) resume() (n, erreurs int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, x := range s.m {
		n += x.n
		erreurs += x.erreurs
	}
	return
}

func (s *stats) total() (n int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, x := range s.m {
		n += x.n
	}
	return
}

func (s *stats) afficher(duree time.Duration) {
	s.mu.Lock()
	defer s.mu.Unlock()
	noms := make([]string, 0, len(s.m))
	tot := 0
	for n, x := range s.m {
		noms = append(noms, n)
		tot += x.n
	}
	sort.Strings(noms)
	fmt.Printf("\n%-42s %7s %7s %9s %9s %9s\n", "requête", "exéc.", "erreurs", "moy. ms", "p95 ms", "max ms")
	for _, n := range noms {
		x := s.m[n]
		slices.Sort(x.durees)
		var somme time.Duration
		for _, d := range x.durees {
			somme += d
		}
		ms := func(d time.Duration) float64 { return float64(d.Microseconds()) / 1000 }
		fmt.Printf("%-42s %7d %7d %9.1f %9.1f %9.1f\n", n, x.n, x.erreurs,
			ms(somme/time.Duration(x.n)), ms(x.durees[len(x.durees)*95/100]), ms(x.durees[len(x.durees)-1]))
	}
	fmt.Printf("\n%d exécutions en %s, %.1f par seconde\n", tot, duree.Round(time.Second), float64(tot)/duree.Seconds())
	for _, n := range noms {
		if x := s.m[n]; x.erreurs > 0 {
			fmt.Printf("dernière erreur de %s : %s\n", n, x.derniere)
		}
	}
}

// parc dit d'où chaque application se connecte quand -postes est donné : le back-office
// depuis les postes des employés, autant que demandé, les autres depuis quelques serveurs.
var parc = map[string]struct {
	prefixe string
	max     int // 0 : autant de postes que -postes
}{
	"portail":    {"SRV-WEB", 4},
	"backoffice": {"PC-BUREAU", 0},
	"elearning":  {"SRV-LMS", 2},
	"marketing":  {"SRV-MAILING", 1},
	"rapports":   {"SRV-RAPPORTS", 1},
}

// poste rend le nom de machine que le thread w déclare pour cette application ;
// vide si n vaut 0, et le pilote envoie alors le vrai nom de la machine.
func poste(appli string, w, n int) string {
	if n <= 0 {
		return ""
	}
	p, ok := parc[appli]
	if !ok {
		p.prefixe = "POSTE-" + strings.ToUpper(appli)
	}
	k := n
	if p.max > 0 && p.max < k {
		k = p.max
	}
	return fmt.Sprintf("%s-%02d", p.prefixe, w%k+1)
}

// cible est un serveur visé ; une classe en a un par participant.
type cible struct {
	serveur, base string
}

// lireCibles lit une cible par ligne, « hôte:port [base] » ; sans base, celle de -base.
// Les lignes vides et celles qui commencent par # sont ignorées.
func lireCibles(chemin, baseDefaut string) ([]cible, error) {
	b, err := os.ReadFile(chemin)
	if err != nil {
		return nil, err
	}
	var cs []cible
	for i, l := range strings.Split(string(b), "\n") {
		f := strings.Fields(l)
		if len(f) == 0 || strings.HasPrefix(f[0], "#") {
			continue
		}
		c := cible{f[0], baseDefaut}
		if len(f) > 1 {
			c.base = f[1]
		}
		if len(f) > 2 || c.base == "" {
			return nil, fmt.Errorf("%s, ligne %d : « hôte:port [base] » attendu, et une base, ici ou par -base", chemin, i+1)
		}
		cs = append(cs, c)
	}
	if len(cs) == 0 {
		return nil, fmt.Errorf("%s : aucune cible", chemin)
	}
	return cs, nil
}

type moteur struct {
	mu       sync.Mutex
	dbs      map[string]*sql.DB // une connexion par application et par poste, pour les filtrer dans les traces
	serveur  string
	base     string
	postes   int
	res      *reserves
	adhoc    bool
	variable bool
	maxRes   int
}

// db rend le pool de connexions de l'application, vue depuis le poste du thread w.
func (m *moteur) db(appli string, w int) (*sql.DB, error) {
	cle := appli + "|" + poste(appli, w, m.postes)
	m.mu.Lock()
	defer m.mu.Unlock()
	if db := m.dbs[cle]; db != nil {
		return db, nil
	}
	db, err := connexion(m.serveur, m.base, appli, poste(appli, w, m.postes))
	if err != nil {
		return nil, err
	}
	m.dbs[cle] = db
	return db, nil
}

func (m *moteur) executer(ctx context.Context, rnd *rand.Rand, w int, r requete) error {
	db, err := m.db(r.appli, w)
	if err != nil {
		return err
	}
	vals := map[string]any{}
	for _, g := range r.groupes {
		lignes, err := m.res.charger(ctx, db, g.requete, m.maxRes)
		if err != nil {
			return fmt.Errorf("réserve de %s : %w", g.params[0].nom, err)
		}
		l := lignes[rnd.IntN(len(lignes))]
		if len(l) < len(g.params) {
			return fmt.Errorf("réserve de %s : %d colonnes pour %d paramètres", g.params[0].nom, len(l), len(g.params))
		}
		for i, p := range g.params {
			vals[p.nom] = valeur(l[i], p.typ, m.variable)
		}
	}
	var rows *sql.Rows
	if m.adhoc || r.adhoc || len(vals) == 0 {
		rows, err = db.QueryContext(ctx, enTexte(r.corps, vals))
	} else {
		// Ordre fixe : la déclaration des paramètres fait partie du texte, donc de la clé du cache.
		noms := slices.Sorted(maps.Keys(vals))
		args := make([]any, 0, len(noms))
		for _, n := range noms {
			args = append(args, sql.Named(n[1:], vals[n]))
		}
		rows, err = db.QueryContext(ctx, r.corps, args...)
	}
	if err != nil {
		return err
	}
	defer rows.Close()
	for { // lire tout ce que la requête rend, comme une application qui affiche la page
		for rows.Next() {
		}
		if !rows.NextResultSet() {
			break
		}
	}
	return rows.Err()
}

// version est fixée à la compilation de la release : -ldflags "-X main.version=1.0.0".
var version = "dev"

// authWindows : connexion sous le compte Windows courant (SSPI), sans identifiant
// ni mot de passe. Positionnée par l'option -windows.
var authWindows bool

func connexion(serveur, base, appli, poste string) (*sql.DB, error) {
	dsn, err := chaineConnexion(serveur, base, appli, poste, authWindows)
	if err != nil {
		return nil, err
	}
	return sql.Open("sqlserver", dsn)
}

// chaineConnexion construit l'URL du pilote. Sans utilisateur dans l'URL, go-mssqldb
// passe sous Windows par SSPI avec le compte courant.
func chaineConnexion(serveur, base, appli, poste string, windows bool) (string, error) {
	q := url.Values{}
	q.Set("database", base)
	q.Set("app name", "PachaFormation-"+appli)
	if poste != "" {
		q.Set("workstation id", poste) // déclaré par le client : host_name, HOST_NAME(), client_hostname
	}
	q.Set("encrypt", "true")
	q.Set("TrustServerCertificate", "true")
	u := url.URL{Scheme: "sqlserver", Host: serveur, RawQuery: q.Encode()}
	if !windows {
		mdp := os.Getenv("SQLCMDPASSWORD")
		if mdp == "" {
			mdp = os.Getenv("MSSQL_SA_PASSWORD")
		}
		if mdp == "" {
			return "", errors.New("mot de passe absent : SQLCMDPASSWORD ou MSSQL_SA_PASSWORD, dans l'environnement ou le fichier --env (ou -windows)")
		}
		user := os.Getenv("WORKLOAD_USER")
		if user == "" {
			user = "sa"
		}
		u.User = url.UserPassword(user, mdp)
	}
	return u.String(), nil
}

func main() {
	env := flag.String("env", ".env", "fichier .env (mot de passe)")
	serveur := flag.String("serveur", "localhost:11433", "hôte:port")
	base := flag.String("base", "", "base visée (obligatoire, sauf si chaque ligne de -cibles la donne)")
	fichierCibles := flag.String("cibles", "", "fichier des serveurs visés, une ligne « hôte:port [base] » par serveur ; remplace -serveur")
	threads := flag.Int("threads", 8, "utilisateurs simultanés, par cible")
	dossier := flag.String("requetes", "requetes", "dossier des fichiers .sql")
	duree := flag.Duration("duree", 5*time.Minute, "durée du tir")
	pause := flag.Duration("pause", 200*time.Millisecond, "pause maximale entre deux requêtes d'un thread (tirée entre 0 et cette valeur)")
	ecritures := flag.Bool("ecritures", false, "inclure les requêtes qui écrivent (refusé sur PachaDataFormation, sauf -forcer-ecritures)")
	forcer := flag.Bool("forcer-ecritures", false, "autoriser -ecritures sur une base nommée PachaDataFormation (les copies des participants d'une salle)")
	adhoc := flag.Bool("adhoc", false, "envoyer toutes les requêtes en texte, littéraux concaténés, au lieu de sp_executesql")
	variable := flag.Bool("longueurs-variables", false, "déclarer les chaînes à la longueur de chaque valeur, comme le pilote par défaut (un plan par longueur)")
	filtre := flag.String("filtre", "", "expression régulière sur le nom des requêtes à garder")
	appli := flag.String("appli", "", "ne garder que les requêtes de cette application")
	graine := flag.Uint64("graine", 0, "graine du tirage (0 : selon l'horloge)")
	timeout := flag.Duration("timeout", 2*time.Minute, "délai maximal d'une requête")
	verifier := flag.Bool("verifier", false, "exécuter chaque requête une fois, dans l'ordre, et dire ce qui échoue")
	postes := flag.Int("postes", 0, "simuler des machines clientes : nombre de postes du back-office (0 : le vrai nom de la machine)")
	liste := flag.Bool("liste", false, "lister les requêtes et leur poids, sans se connecter")
	flag.BoolVar(&authWindows, "windows", false, "authentification Windows avec le compte courant (Windows seulement), au lieu de sa et d'un mot de passe")
	montrerVersion := flag.Bool("version", false, "afficher la version et quitter")
	flag.Parse()

	if *montrerVersion {
		fmt.Println("pachaworkload", version)
		return
	}
	if authWindows && runtime.GOOS != "windows" {
		fmt.Fprintln(os.Stderr, "-windows ne fonctionne que sous Windows")
		os.Exit(2)
	}

	if err := dotenv.Load(*env); err != nil {
		fmt.Fprintln(os.Stderr, "avertissement :", err)
	}
	fichiers, _ := filepath.Glob(filepath.Join(*dossier, "*.sql"))
	var garde *regexp.Regexp
	if *filtre != "" {
		garde = regexp.MustCompile(*filtre)
	}
	var reqs []requete
	for _, f := range fichiers {
		r, err := lireRequete(f)
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(2)
		}
		if (r.ecriture && !*ecritures) || (garde != nil && !garde.MatchString(r.nom)) || (*appli != "" && r.appli != *appli) {
			continue
		}
		reqs = append(reqs, r)
	}
	if len(reqs) == 0 {
		fmt.Fprintln(os.Stderr, "aucune requête retenue")
		os.Exit(2)
	}
	if *liste {
		tot := 0
		for _, r := range reqs {
			tot += r.poids
		}
		for _, r := range reqs {
			e := ""
			if r.ecriture {
				e = "écriture"
			}
			fmt.Printf("%-42s %-12s %4d  %5.1f %%  %s\n", r.nom, r.appli, r.poids, 100*float64(r.poids)/float64(tot), e)
		}
		return
	}
	cibles := []cible{{*serveur, *base}}
	if *fichierCibles != "" {
		var err error
		if cibles, err = lireCibles(*fichierCibles, *base); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(2)
		}
	}
	for _, c := range cibles {
		if c.base == "" {
			fmt.Fprintln(os.Stderr, "-base est obligatoire")
			os.Exit(2)
		}
		if *ecritures && !*forcer && strings.EqualFold(c.base, "PachaDataFormation") {
			fmt.Fprintf(os.Stderr, "refus : %s, les écritures ne tournent pas sur la base de référence ; restaurer une copie, ou -forcer-ecritures si ce n'est pas la référence (README.md)\n", c.serveur)
			os.Exit(2)
		}
	}

	ctx, arret := signal.NotifyContext(context.Background(), os.Interrupt)
	defer arret()

	// Un moteur par cible : ses connexions, et ses réserves de paramètres, lues sur ses propres données.
	// Une cible injoignable est écartée, les autres tirent quand même.
	var moteurs []*moteur
	var gardees []cible
	for _, c := range cibles {
		m := &moteur{dbs: map[string]*sql.DB{}, serveur: c.serveur, base: c.base, postes: *postes,
			res: &reserves{lignes: map[string][][]any{}}, adhoc: *adhoc, variable: *variable, maxRes: 20000}
		db, err := m.db(reqs[0].appli, 0)
		if err == nil {
			p, fin := context.WithTimeout(ctx, 10*time.Second)
			err = db.PingContext(p)
			fin()
		}
		if err != nil {
			fmt.Fprintf(os.Stderr, "cible écartée, %s %s : %v\n", c.serveur, c.base, err)
			continue
		}
		moteurs, gardees = append(moteurs, m), append(gardees, c)
	}
	if len(moteurs) == 0 {
		fmt.Fprintln(os.Stderr, "aucune cible joignable")
		os.Exit(2)
	}
	nom := func(c cible) string { return c.serveur + " " + c.base }

	if *verifier {
		ko := 0
		for i, m := range moteurs {
			if len(moteurs) > 1 {
				fmt.Printf("== %s\n", nom(gardees[i]))
			}
			rnd := rand.New(rand.NewPCG(*graine, 1))
			for _, r := range reqs {
				c, fin := context.WithTimeout(ctx, *timeout)
				t := time.Now()
				err := m.executer(c, rnd, 0, r)
				fin()
				etat := "ok"
				if err != nil {
					etat, ko = "ÉCHEC : "+err.Error(), ko+1
				}
				fmt.Printf("%-42s %8.0f ms  %s\n", r.nom, float64(time.Since(t).Milliseconds()), etat)
			}
		}
		fmt.Printf("\n%d requêtes sur %d cibles, %d en échec\n", len(reqs), len(moteurs), ko)
		if ko > 0 {
			os.Exit(1)
		}
		return
	}

	// Tirage pondéré : une table cumulée, un tirage par exécution.
	cumul := make([]int, len(reqs))
	tot := 0
	for i, r := range reqs {
		tot += r.poids
		cumul[i] = tot
	}
	if tot == 0 {
		fmt.Fprintln(os.Stderr, "toutes les requêtes retenues ont un poids nul ; -verifier les exécute quand même")
		os.Exit(2)
	}
	st := &stats{m: map[string]*mesure{}}
	parCible := make([]*stats, len(moteurs))
	debut := time.Now()
	ctx, fin := context.WithTimeout(ctx, *duree)
	defer fin()
	var wg sync.WaitGroup
	for i, m := range moteurs {
		parCible[i] = &stats{m: map[string]*mesure{}}
		for w := range *threads {
			n := uint64(i**threads + w) // numéro global du thread, pour des graines distinctes
			graineThread := *graine + n
			if *graine == 0 {
				graineThread = uint64(time.Now().UnixNano()) + n
			}
			rnd := rand.New(rand.NewPCG(graineThread, n))
			wg.Go(func() {
				for ctx.Err() == nil {
					r := reqs[sort.SearchInts(cumul, rnd.IntN(tot)+1)]
					c, f := context.WithTimeout(ctx, *timeout)
					t := time.Now()
					err := m.executer(c, rnd, w, r)
					f()
					if ctx.Err() != nil {
						return // interrompue par la fin du tir, ne compte pas
					}
					st.noter(r.nom, time.Since(t), err)
					parCible[i].noter(r.nom, time.Since(t), err)
					if *pause > 0 {
						select {
						case <-ctx.Done():
						case <-time.After(time.Duration(rnd.Int64N(int64(*pause)))):
						}
					}
				}
			})
		}
	}
	go func() {
		for range time.Tick(10 * time.Second) {
			fmt.Fprintf(os.Stderr, "%s  %d exécutions\n", time.Since(debut).Round(time.Second), st.total())
		}
	}()
	wg.Wait()
	ecoule := time.Since(debut)
	st.afficher(ecoule)
	if len(moteurs) > 1 {
		fmt.Printf("\n%-40s %9s %8s %9s\n", "cible", "exéc.", "erreurs", "par sec.")
		for i, c := range gardees {
			n, e := parCible[i].resume()
			fmt.Printf("%-40s %9d %8d %9.1f\n", nom(c), n, e, float64(n)/ecoule.Seconds())
		}
	}
}
