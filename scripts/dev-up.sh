#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

COMPOSE="docker compose"
TIMEOUT_MIN=${TIMEOUT_MIN:-10}

echo "Starting Docker stack (detached)..."
$COMPOSE up -d

echo "\nFollowing bootstrap logs until WooCommerce is active (timeout: ${TIMEOUT_MIN}m)..."
end=$((SECONDS + TIMEOUT_MIN*60))

set +e
$COMPOSE logs -f bootstrap &
LOGPID=$!
set -e

while true; do
  if $COMPOSE exec -T wpcli wp plugin is-active woocommerce >/dev/null 2>&1; then
    echo "\nWooCommerce is active."
    break
  fi
  if (( SECONDS >= end )); then
    echo "\nTimed out waiting for WooCommerce activation." >&2
    break
  fi
  sleep 3
done

if kill -0 "$LOGPID" 2>/dev/null; then
  kill "$LOGPID" 2>/dev/null || true
fi

echo "\n--- Final status ---"
set +e
$COMPOSE exec -T wpcli wp plugin status woocommerce || true
echo "\nTip: run '$COMPOSE logs -f bootstrap' anytime to watch bootstrap progress."
