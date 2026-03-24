#!/usr/bin/env bash

# Source shared logging helpers (log, err, checkvars)
source "$(dirname "$0")/template_script.sh"

# --------------------------------------------------------------------------

ENV_FILE="/srv/infra/backup/.env"
EXCLUDE_FILE="/srv/infra/backup/excludes.txt"
DUMP_DIR="/tmp/restic-dumps"
DATE=$(date +%Y%m%d_%H%M%S)

OVERALL_STATUS="success"
ERRORS=""

# --------------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------------

[ -f "$ENV_FILE" ] || err "Env file not found: $ENV_FILE"

set -a
# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

checkvars \
  AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY \
  RESTIC_REPOSITORY RESTIC_PASSWORD \
  POSTGRES_USER POSTGRES_PASSWORD \
  MONGO_ROOT_USER MONGO_ROOT_PASSWORD

cleanup() {
  log INFO "Cleaning up temp dumps..."
  rm -rf "$DUMP_DIR"
}
trap cleanup EXIT

mkdir -p "$DUMP_DIR"

log INFO "====== Backup started: $(date) ======"

# --------------------------------------------------------------------------
# PostgreSQL dump
# --------------------------------------------------------------------------

log INFO "Dumping PostgreSQL..."

if docker exec \
    -e PGPASSWORD="$POSTGRES_PASSWORD" \
    postgres \
    pg_dumpall -U "$POSTGRES_USER" \
    > "$DUMP_DIR/postgres_${DATE}.sql" 2>&1; then
  log SUCCESS "PostgreSQL dump complete"
else
  log WARN "PostgreSQL dump failed — continuing without it"
  OVERALL_STATUS="partial"
  ERRORS+="PostgreSQL dump failed. "
fi

# --------------------------------------------------------------------------
# MongoDB dump
# --------------------------------------------------------------------------

log INFO "Dumping MongoDB..."

MONGO_DUMP_PATH_IN_CONTAINER="/tmp/mongodb_${DATE}"

if docker exec mongodb mongodump \
    -u "$MONGO_ROOT_USER" \
    -p "$MONGO_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    --out "$MONGO_DUMP_PATH_IN_CONTAINER" \
    --quiet 2>&1; then
  # Copy dump out of container, then clean up inside container
  docker cp "mongodb:${MONGO_DUMP_PATH_IN_CONTAINER}" "$DUMP_DIR/mongodb_${DATE}"
  docker exec mongodb rm -rf "$MONGO_DUMP_PATH_IN_CONTAINER"
  log SUCCESS "MongoDB dump complete"
else
  log WARN "MongoDB dump failed — continuing without it"
  OVERALL_STATUS="partial"
  ERRORS+="MongoDB dump failed. "
fi

# --------------------------------------------------------------------------
# Restic backup
# --------------------------------------------------------------------------

log INFO "Running restic backup..."

if restic backup /srv "$DUMP_DIR" \
    --exclude-file="$EXCLUDE_FILE" \
    --tag "mothership" \
    --tag "daily" 2>&1; then
  log SUCCESS "Restic backup complete"
else
  log ERROR "Restic backup failed"
  OVERALL_STATUS="failure"
  ERRORS+="Restic backup failed. "
fi

# --------------------------------------------------------------------------
# Retention policy (only if backup didn't fully fail)
# --------------------------------------------------------------------------

if [ "$OVERALL_STATUS" != "failure" ]; then
  log INFO "Applying retention policy..."

  if restic forget --prune \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 3 \
      --tag "mothership" 2>&1; then
    log SUCCESS "Retention policy applied"
  else
    log WARN "Restic forget/prune failed"
    OVERALL_STATUS="partial"
    ERRORS+="Restic prune failed. "
  fi
fi

# --------------------------------------------------------------------------
# n8n notification
# --------------------------------------------------------------------------

if [ -n "${BACKUP_NOTIFY_URL:-}" ]; then
  log INFO "Sending notification to n8n..."

  MESSAGE="${ERRORS:-Backup completed successfully.}"
  PAYLOAD=$(printf '{"status":"%s","server":"mothership","timestamp":"%s","message":"%s"}' \
    "$OVERALL_STATUS" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$MESSAGE")

  curl -s -X POST "$BACKUP_NOTIFY_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null \
    || log WARN "Failed to send n8n notification"
fi

# --------------------------------------------------------------------------
# Final result
# --------------------------------------------------------------------------

if [ "$OVERALL_STATUS" = "success" ]; then
  log SUCCESS "====== Backup finished successfully: $(date) ======"
  exit 0
elif [ "$OVERALL_STATUS" = "partial" ]; then
  log WARN "====== Backup finished with warnings: $ERRORS ======"
  exit 1
else
  log ERROR "====== Backup FAILED: $ERRORS ======"
  exit 1
fi
