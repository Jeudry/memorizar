package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/Jeudry/memorizar/backend/internal/httpapi"
	"github.com/Jeudry/memorizar/backend/internal/notify"
	filerepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/file"
	sqliterepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/sqlite"
	"github.com/Jeudry/memorizar/backend/internal/social/application"
	"github.com/Jeudry/memorizar/backend/internal/social/ports"
)

func main() {
	addr := envOrDefault("MEMORIZAR_API_ADDR", ":8080")

	// Modo healthcheck: usado por Docker (la imagen distroless no trae shell
	// ni curl). Hace GET a /healthz y sale 0/1 según el estado.
	healthcheck := flag.Bool("healthcheck", false, "ping /healthz and exit")
	flag.Parse()
	if *healthcheck {
		runHealthcheck(addr)
		return
	}

	driver := envOrDefault("MEMORIZAR_STORE", "sqlite")

	var repo ports.Repository
	switch driver {
	case "file":
		dataPath := envOrDefault(
			"MEMORIZAR_SOCIAL_STORE",
			filepath.Join("data", "social_store.json"),
		)
		fileRepo, err := filerepo.NewRepository(dataPath)
		if err != nil {
			log.Fatalf("load file repository: %v", err)
		}
		repo = fileRepo
		log.Printf("memorizar api using file store at %s", dataPath)
	case "sqlite", "":
		dbPath := envOrDefault(
			"MEMORIZAR_SQLITE_PATH",
			filepath.Join("data", "memorizar.db"),
		)
		if err := os.MkdirAll(filepath.Dir(dbPath), 0o755); err != nil {
			log.Fatalf("mkdir for sqlite: %v", err)
		}
		sqlRepo, err := sqliterepo.Open(dbPath)
		if err != nil {
			log.Fatalf("open sqlite: %v", err)
		}
		defer sqlRepo.Close()
		repo = sqlRepo
		log.Printf("memorizar api using sqlite at %s", dbPath)
	default:
		log.Fatalf("unknown MEMORIZAR_STORE driver: %q (use 'sqlite' or 'file')", driver)
	}

	// Notifier: FcmNotifier (push real) si hay credenciales de service account
	// en MEMORIZAR_FCM_CREDENTIALS_FILE; si no, LogNotifier (stdout).
	notifier := buildNotifier(repo)
	moderatorEmails := strings.Split(os.Getenv("MEMORIZAR_MODERATOR_EMAILS"), ",")
	service := application.NewService(repo,
		application.WithNotifier(notifier),
		application.WithModeratorEmails(moderatorEmails),
	)
	server := httpapi.NewServer(service)

	log.Printf("memorizar api listening on %s", addr)
	if err := http.ListenAndServe(addr, server.Handler()); err != nil {
		log.Fatal(err)
	}
}

// runHealthcheck consulta /healthz en el addr local y termina el proceso con
// código 0 (sano) o 1 (no responde / status != 200).
func runHealthcheck(addr string) {
	host := addr
	if strings.HasPrefix(host, ":") {
		host = "127.0.0.1" + host
	}
	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://" + host + "/healthz")
	if err != nil {
		log.Printf("healthcheck failed: %v", err)
		os.Exit(1)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		log.Printf("healthcheck unhealthy: status %d", resp.StatusCode)
		os.Exit(1)
	}
}

func envOrDefault(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

// buildNotifier devuelve un FcmNotifier (push real vía FCM HTTP v1) si está
// configurado MEMORIZAR_FCM_CREDENTIALS_FILE con un service account válido; en
// cualquier otro caso cae al LogNotifier (stdout), de modo que el servidor
// arranca igual sin Firebase configurado.
func buildNotifier(repo ports.Repository) notify.Notifier {
	credPath := os.Getenv("MEMORIZAR_FCM_CREDENTIALS_FILE")
	if credPath == "" {
		log.Printf("push: LogNotifier (FCM no configurado; set MEMORIZAR_FCM_CREDENTIALS_FILE para push real)")
		return notify.LogNotifier{}
	}
	creds, err := os.ReadFile(credPath)
	if err != nil {
		log.Printf("push: no se pudo leer %s (%v) — fallback a LogNotifier", credPath, err)
		return notify.LogNotifier{}
	}
	tokensFor := func(userID string) ([]string, error) {
		tokens, err := repo.ListPushTokensByUser(userID)
		if err != nil {
			return nil, err
		}
		out := make([]string, 0, len(tokens))
		for _, t := range tokens {
			if t.Token != "" {
				out = append(out, t.Token)
			}
		}
		return out, nil
	}
	fcm, err := notify.NewFcmNotifier(context.Background(), creds, tokensFor)
	if err != nil {
		log.Printf("push: FCM inválido (%v) — fallback a LogNotifier", err)
		return notify.LogNotifier{}
	}
	log.Printf("push: FcmNotifier habilitado (FCM HTTP v1)")
	return fcm
}
