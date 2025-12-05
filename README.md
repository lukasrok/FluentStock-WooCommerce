# FluentStock WooCommerce Dev

Fast, zero-setup WordPress + WooCommerce using Docker Compose on Windows.

The repo ships with a DB snapshot and media uploads so a fresh clone runs instantly with products and settings. WooCommerce installs from a local zip for deterministic first runs.

## Quick Start (Zero‑touch)

1. Clone the repo:
	```bash
	git clone https://github.com/lukasrok/FluentStock-WooCommerce.git
	cd FluentStock-WooCommerce
	```

2. Start the stack:
	```bash
	docker compose up -d
	```

	To watch install/activation progress in your terminal, use:
	```bash
	bash scripts/dev-up.sh
	```

3. Open http://localhost:8000 — site is ready. No installer needed.
	- A snapshot DB (`data/wordpress.sql`) auto-imports on first run (if provided).
	- WooCommerce installs and activates from local zip (`vendor/plugins/woocommerce.zip`).
	- URLs auto-update to `WP_HOME` (default http://localhost:8000).
	- Admin: http://localhost:8000/wp-admin

First run timing (important):
- After `docker compose up -d`, allow up to 5 minutes for WooCommerce to fully install and activate on slower machines.
- Validation: refresh the homepage — you should see store products (not the default blog). Also try `http://localhost:8000/shop`.
- Optional CLI check:
  ```bash
  docker compose exec wpcli wp plugin status woocommerce
  ```

## Deterministic WooCommerce Install (Local Zip)

- Place the official WooCommerce plugin zip at `vendor/plugins/woocommerce.zip` before starting (already included here).
- On boot, the stack installs from this local file (no network), ensuring deterministic first-run behavior.
- To allow a remote fallback (not recommended for CI), set env `WC_ALLOW_NETWORK_FALLBACK=1` for `bootstrap`/`wpcli`.

## Common Commands

- Start: `docker compose up -d`
- Stop: `docker compose down`
- Rebuild: `docker compose build --no-cache`
- WP-CLI core version: `docker compose exec wpcli wp core version`
- Flush cache: `docker compose exec wpcli wp cache flush`
- Reset admin password: `docker compose exec wpcli wp user update admin --user_pass="yourNewPass"`
- Update URLs (if needed): `docker compose exec wpcli wp search-replace 'http://old-host' 'http://localhost:8000' --all-tables`

## Project Contents

- `docker-compose.yml`: Services — `web` (WordPress + Apache), `db` (MariaDB), `bootstrap` (one-shot), `wpcli` (interactive).
- `wp-content/mu-plugins/`: MU plugins for auto-permalinks and guaranteed WooCommerce activation.
- `vendor/plugins/woocommerce.zip`: Local plugin zip used for deterministic installs.
- `scripts/ensure-plugins.sh`: Deterministic install/activate with retries.
- `scripts/dev-up.sh`: Start + follow logs until activation.

## CI

- The workflow is present but disabled by default (manual `workflow_dispatch`).

## Security Note

This repo includes demo data for local development. Avoid adding secrets or sensitive data.
# FluentStock-WooCommerce

Repository reset to a clean initial commit per request.
