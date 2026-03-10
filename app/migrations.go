package app

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/revel/revel"
)

/*runMigrations creates the schema_migrations tracking table if needed, then
applies all pending numbered SQL files from scripts/db/migrations/ in order. */
func runMigrations() {

	revel.AppLog.Info("running DB migrations")

	_, err := Db.Exec(`
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version     integer                   PRIMARY KEY,
			filename    varchar(255)              NOT NULL,
			applied_at  timestamp with time zone  NOT NULL DEFAULT now()
		)
	`)
	if err != nil {
		revel.AppLog.Fatal("failed to create schema_migrations table", "error", err.Error())
	}

	//collect already applied versions
	var applied []int
	if err = Db.Select(&applied, `SELECT version FROM schema_migrations ORDER BY version`); err != nil {
		revel.AppLog.Fatal("failed to read schema_migrations", "error", err.Error())
	}
	appliedSet := make(map[int]bool, len(applied))
	for _, v := range applied {
		appliedSet[v] = true
	}

	//find migration files
	migrationsDir := filepath.Join(revel.BasePath, "scripts", "db", "migrations")
	files, err := ioutil.ReadDir(migrationsDir)
	if err != nil {
		revel.AppLog.Fatal("failed to read migrations directory", "path", migrationsDir, "error", err.Error())
	}

	//collect and sort .sql files
	var sqlFiles []string
	for _, f := range files {
		if !f.IsDir() && strings.HasSuffix(f.Name(), ".sql") {
			sqlFiles = append(sqlFiles, f.Name())
		}
	}
	sort.Strings(sqlFiles)

	//run pending migrations
	for _, filename := range sqlFiles {

		version, err := parseMigrationVersion(filename)
		if err != nil {
			revel.AppLog.Fatal("invalid migration filename", "file", filename, "error", err.Error())
		}

		if appliedSet[version] {
			continue
		}

		content, err := ioutil.ReadFile(filepath.Join(migrationsDir, filename))
		if err != nil {
			revel.AppLog.Fatal("failed to read migration file", "file", filename, "error", err.Error())
		}

		tx, err := Db.Beginx()
		if err != nil {
			revel.AppLog.Fatal("failed to begin migration transaction", "file", filename, "error", err.Error())
		}

		if _, err = tx.Exec(string(content)); err != nil {
			tx.Rollback()
			revel.AppLog.Fatal("failed to apply migration", "file", filename, "error", err.Error())
		}

		if _, err = tx.Exec(
			`INSERT INTO schema_migrations (version, filename) VALUES ($1, $2)`,
			version, filename,
		); err != nil {
			tx.Rollback()
			revel.AppLog.Fatal("failed to record migration", "file", filename, "error", err.Error())
		}

		tx.Commit()
		revel.AppLog.Info("applied migration", "file", filename)
	}

	revel.AppLog.Info("DB migrations complete")
}

//parseMigrationVersion extracts the leading integer from a filename like "001_foo.sql"
func parseMigrationVersion(filename string) (int, error) {

	parts := strings.SplitN(filename, "_", 2)
	if len(parts) < 2 {
		return 0, fmt.Errorf("filename must start with a number prefix, e.g. 001_name.sql")
	}
	version, err := strconv.Atoi(parts[0])
	if err != nil {
		return 0, fmt.Errorf("non-numeric version prefix in %q: %w", filename, err)
	}
	return version, nil
}
