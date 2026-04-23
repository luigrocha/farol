#!/usr/bin/env bash
# db_migrate.sh — Run Flyway migrations against Supabase.
# Requires: Java 11+, Flyway CLI (https://flywaydb.org/download)
# Usage:
#   ./scripts/db_migrate.sh            # migrate
#   ./scripts/db_migrate.sh info       # show migration status
#   ./scripts/db_migrate.sh validate   # validate applied migrations
#   ./scripts/db_migrate.sh repair     # repair checksum mismatches

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

# Load .env if present
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
else
  echo "⚠  No .env file found. Copy .env.example to .env and fill in credentials."
  exit 1
fi

# Validate required env vars
: "${FLYWAY_URL:?FLYWAY_URL is not set in .env}"
: "${FLYWAY_USER:?FLYWAY_USER is not set in .env}"
: "${FLYWAY_PASSWORD:?FLYWAY_PASSWORD is not set in .env}"

COMMAND="${1:-migrate}"

echo "▶  flyway $COMMAND"
flyway \
  -configFiles="$ROOT_DIR/database/flyway.conf" \
  "$COMMAND"

echo "✓  Done"
