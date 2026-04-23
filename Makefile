.PHONY: db-migrate db-info db-validate db-repair db-baseline

## Run pending migrations
db-migrate:
	./scripts/db_migrate.sh migrate

## Show current migration status
db-info:
	./scripts/db_migrate.sh info

## Validate applied migrations against local checksums
db-validate:
	./scripts/db_migrate.sh validate

## Repair checksum mismatches in the schema_history table
db-repair:
	./scripts/db_migrate.sh repair

## Baseline an existing database (first-time setup on an already-populated DB)
db-baseline:
	./scripts/db_migrate.sh baseline
