// Comando para migrar el store legacy `data/social_store.json` a SQLite.
// Uso:
//
//	go run cmd/migrate-store/main.go \
//	    --from data/social_store.json \
//	    --to   data/memorizar.db
//
// Idempotente: re-ejecutarlo no duplica filas (usa INSERT OR REPLACE en
// el repositorio SQLite).
package main

import (
	"flag"
	"log"

	filerepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/file"
	sqliterepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/sqlite"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

func main() {
	from := flag.String("from", "data/social_store.json", "ruta al JSON legacy")
	to := flag.String("to", "data/memorizar.db", "ruta a la DB SQLite destino")
	flag.Parse()

	src, err := filerepo.NewRepository(*from)
	if err != nil {
		log.Fatalf("abrir source %s: %v", *from, err)
	}
	dst, err := sqliterepo.Open(*to)
	if err != nil {
		log.Fatalf("abrir destino %s: %v", *to, err)
	}
	defer dst.Close()

	users, err := src.ListUsers()
	if err != nil {
		log.Fatalf("list users: %v", err)
	}
	log.Printf("migrando %d usuarios...", len(users))
	for _, u := range users {
		if err := dst.SaveUser(u); err != nil {
			log.Fatalf("save user %s: %v", u.ID, err)
		}
	}

	migrateUserDependents := func(u domain.User) {
		// Friendships donde aparezca el usuario.
		for _, status := range []domain.FriendshipStatus{domain.FriendshipPending, domain.FriendshipAccepted} {
			fs, err := src.ListFriendships(u.ID, status)
			if err != nil {
				log.Fatalf("list friendships: %v", err)
			}
			for _, f := range fs {
				if err := dst.SaveFriendship(f); err != nil {
					log.Fatalf("save friendship: %v", err)
				}
			}
		}
		// Achievements y activities por user.
		achievements, _ := src.ListAchievementsByUserIDs([]string{u.ID})
		for _, a := range achievements {
			_ = dst.SaveAchievement(a)
		}
		activities, _ := src.ListActivitiesByUserIDs([]string{u.ID})
		for _, a := range activities {
			_ = dst.SaveActivity(a)
		}
		// Shares.
		shares, _ := src.ListSharedResourcesForUser(u.ID)
		for _, s := range shares {
			_ = dst.SaveSharedResource(s)
		}
		// Last progress snapshot.
		if snap, err := src.FindLatestProgressSnapshot(u.ID); err == nil && snap != nil {
			_ = dst.SaveProgressSnapshot(*snap)
		}
	}
	for _, u := range users {
		migrateUserDependents(u)
	}

	log.Printf("✅ migración completa → %s", *to)
}
