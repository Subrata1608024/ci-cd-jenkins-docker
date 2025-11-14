#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:5000/health}"
SERVICE="${2:-app}"

echo "Waiting for service '$SERVICE' to be healthy at: $URL"

# Wait for HTTP endpoint to respond OK
attempts=30
for i in $(seq 1 $attempts); do
  if curl -fsS "$URL" >/dev/null 2>&1; then
    echo "HTTP health endpoint is OK."
    break
  fi
  echo "Health not ready yet (attempt $i/$attempts)..."
  sleep 2
done

# Verify Docker health status
CID="$(docker compose ps -q app || true)"
if [ -z "$CID" ]; then
  echo "No container found for service 'app'"
  exit 1
fi

STATUS="$(docker inspect --format='{{json .State.Health.Status}}' "$CID" 2>/dev/null | tr -d '"')"
echo "Container health: ${STATUS:-unknown}"

if [ "$STATUS" = "healthy" ]; then
  echo "Health check passed."
  exit 0
else
  echo "Health check failed (status=$STATUS)."
  exit 1
fi
