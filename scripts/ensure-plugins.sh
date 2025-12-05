#!/usr/bin/env bash
# tolerate shells lacking pipefail (fallback to -eu)
set -euo pipefail 2>/dev/null || set -eu

cd /var/www/html

# Deterministic local WooCommerce install by default.
# Provide the official zip at vendor/plugins/woocommerce.zip (on host).
# To allow remote fallback set env WC_ALLOW_NETWORK_FALLBACK=1.
LOCAL_WC_ZIP="${WC_LOCAL_ZIP:-/var/www/html/vendor/plugins/woocommerce.zip}"
ALLOW_NET="${WC_ALLOW_NETWORK_FALLBACK:-0}"
DB_DUMP_PATH="/var/www/html/data/wordpress.sql"

TARGET_URL="${WP_HOME:-http://localhost:8000}"

# Ensure WordPress core files are present before using wp-cli
until [ -f wp-includes/version.php ]; do
  echo "Waiting for WordPress core files to be present..."
  sleep 2
done

# If WordPress is not installed and a DB dump exists, auto-import to skip setup
if ! wp core is-installed >/dev/null 2>&1; then
  if [ -f "${DB_DUMP_PATH}" ]; then
    echo "Found database dump at ${DB_DUMP_PATH}; importing to skip setup..."
    if [ ! -f wp-config.php ]; then
      echo "wp-config.php not found; creating from environment..."
      wp config create \
        --dbname="${WORDPRESS_DB_NAME:-wordpress}" \
        --dbuser="${WORDPRESS_DB_USER:-wordpress}" \
        --dbpass="${WORDPRESS_DB_PASSWORD:-wordpress}" \
        --dbhost="${WORDPRESS_DB_HOST:-db:3306}" \
        --skip-check || true
    fi
    wp db create || true
    wp db import "${DB_DUMP_PATH}"
  else
    # Otherwise, wait for manual install to complete
    until wp core is-installed >/dev/null 2>&1; do
      echo "Waiting for WordPress to be ready..."
      sleep 2
    done
  fi
fi

# Align site URLs once (safe if set already)
if ! wp option get fs_bootstrap_urls_done >/dev/null 2>&1; then
  CURRENT_URL="$(wp option get siteurl 2>/dev/null || true)"
  if [ -n "${CURRENT_URL}" ] && [ "${CURRENT_URL}" != "${TARGET_URL}" ]; then
    echo "Updating URLs: ${CURRENT_URL} -> ${TARGET_URL} (all tables)"
    wp search-replace "${CURRENT_URL}" "${TARGET_URL}" --all-tables --precise --recurse-objects --skip-columns=guid || true
  fi
  wp option update fs_bootstrap_urls_done 1 || true
fi

ensure_woocommerce() {
  echo "Ensuring WooCommerce is installed and active (local-first deterministic)..."
  mkdir -p wp-content/upgrade wp-content/plugins || true

  # retry up to 30 minutes total
  deadline=$(( $(date +%s) + 1800 ))
  attempt=0
  delay=5
  while [ $(date +%s) -lt ${deadline} ]; do
    attempt=$(( attempt + 1 ))
    if wp plugin is-active woocommerce >/dev/null 2>&1; then
      echo "WooCommerce active."
      return 0
    fi

    if wp plugin is-installed woocommerce >/dev/null 2>&1; then
      echo "Activating WooCommerce (attempt ${attempt})..."
      if wp plugin activate woocommerce >/dev/null 2>&1; then
        echo "WooCommerce activated."
        return 0
      else
        echo "Activation failed, cleaning any partial state and retrying..." >&2
        rm -rf wp-content/plugins/woocommerce || true
      fi
    fi

    echo "Installing WooCommerce (attempt ${attempt})..."
    if [ -f "${LOCAL_WC_ZIP}" ]; then
      echo "Using local zip: ${LOCAL_WC_ZIP}"
      if wp plugin install "${LOCAL_WC_ZIP}" --activate --force >/dev/null 2>&1; then
        echo "WooCommerce installed and activated from local zip."
        return 0
      fi
      echo "Local zip install failed on attempt ${attempt}." >&2
    elif [ "${ALLOW_NET}" = "1" ]; then
      echo "Local zip not found; attempting network fallback (attempt ${attempt})."
      if wp plugin install woocommerce --activate --force >/dev/null 2>&1; then
        echo "WooCommerce installed and activated from network."
        return 0
      fi
    else
      echo "Local zip missing at ${LOCAL_WC_ZIP}. Provide the file or set WC_ALLOW_NETWORK_FALLBACK=1." >&2
    fi

    echo "Attempt ${attempt} failed; retrying in ${delay}s..."
    sleep ${delay}
    delay=$(( delay * 2 )); if [ ${delay} -gt 60 ]; then delay=60; fi
  done

  echo "ERROR: Timed out waiting for WooCommerce to be active." >&2
  return 1
}

WC_BOOTSTRAP_DONE=$(wp option get fs_bootstrap_wc_done 2>/dev/null || echo "0")
if [ "${WC_BOOTSTRAP_DONE}" = "1" ] && wp plugin is-active woocommerce >/dev/null 2>&1; then
  echo "WooCommerce already active (bootstrap done)."
else
  if ensure_woocommerce; then
    wp option update fs_bootstrap_wc_done 1 || true
  else
    exit 1
  fi
fi

wp cache flush || true
wp rewrite flush --hard || true

echo "Plugin bootstrap complete."
