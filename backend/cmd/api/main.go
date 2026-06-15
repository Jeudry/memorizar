package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/Jeudry/memorizar/backend/internal/httpapi"
	"github.com/Jeudry/memorizar/backend/internal/notify"
	filerepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/file"
	sqliterepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/sqlite"
	"github.com/Jeudry/memorizar/backend/internal/social/application"
	"github.com/Jeudry/memorizar/backend/internal/social/ports"
)

func main() {
	addr := envOrDefault("MEMORIZAR_API_ADDR", ":8080")
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

	// Notifier por defecto: LogNotifier (stdout). Cuando Firebase Admin esté
	// configurado se cambia por FcmNotifier sin tocar el resto del wiring.
	moderatorEmails := strings.Split(os.Getenv("MEMORIZAR_MODERATOR_EMAILS"), ",")
	service := application.NewService(repo,
		application.WithNotifier(notify.LogNotifier{}),
		application.WithModeratorEmails(moderatorEmails),
	)
	server := httpapi.NewServer(service)

	log.Printf("memorizar api listening on %s", addr)
	if err := http.ListenAndServe(addr, server.Handler()); err != nil {
		log.Fatal(err)
	}
}

func envOrDefault(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}
