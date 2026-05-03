package main

import (
	"log"
	"net/http"
	"os"
	"path/filepath"

	"github.com/Jeudry/memorizar/backend/internal/httpapi"
	filerepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/file"
	"github.com/Jeudry/memorizar/backend/internal/social/application"
)

func main() {
	addr := envOrDefault("MEMORIZAR_API_ADDR", ":8080")
	dataPath := envOrDefault(
		"MEMORIZAR_SOCIAL_STORE",
		filepath.Join("data", "social_store.json"),
	)

	repo, err := filerepo.NewRepository(dataPath)
	if err != nil {
		log.Fatalf("load repository: %v", err)
	}
	service := application.NewService(repo)
	server := httpapi.NewServer(service)

	log.Printf("memorizar api listening on %s using %s", addr, dataPath)
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
