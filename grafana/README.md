# Grafana Sandbox

This directory contains a self-contained Grafana instance configured with Docker Compose. The container comes preloaded with the following plugins (installed via `GF_PLUGINS_PREINSTALL_SYNC`):

- yesoreyeram-infinity-datasource (Infinity)
- grafana-mongodb-datasource (MongoDB, requires a Grafana Enterprise license)
- grafana-googlesheets-datasource (Google Sheets)

## Prerequisites
- Docker and Docker Compose installed locally

## Usage
1. From the repo root run:
   ```bash
   cd grafana
   docker compose up -d
   ```
2. Access Grafana at http://localhost:3000. Anonymous access is enabled (no login prompt); the `admin` / `admin` account remains defined but the login form is disabled.
3. To stop the stack:
   ```bash
   docker compose down
   ```

Data is persisted in `grafana/data/`. Provisioning files (dashboards, data sources, etc.) can be added under `grafana/provisioning/` following Grafana's standard structure; they will be mounted automatically.

## Git Sync
- Git Sync stays feature-gated in Grafana OSS 12.3; the compose file already enables the `provisioning` and `kubernetesDashboards` toggles that Grafana’s [Set up Git Sync as code](https://grafana.com/docs/grafana/latest/as-code/observability-as-code/git-sync/git-sync-setup/set-up-code/) guide calls for, so the “Connection” and “Repository” APIs are available as soon as Grafana starts.
- The repository definition (no secrets) lives in `grafana/git-sync/repositories/open-source-north-dashboards.yaml`. Adjust the GitHub URL/branch/path there whenever you need to point at a different repo or folder.
- Credentials are defined via a single template: `grafana/git-sync/connection.template.yaml`. It expects the environment variables `GITHUB_APP_ID`, `GITHUB_INSTALL_ID`, and `GITHUB_PRIVATE_KEY` (a PEM-encoded GitHub App private key). Export them from your 1Password CLI session and run `make git-sync-secrets`; the Makefile uses `envsubst` to render the template into `grafana/git-sync/generated/default__connection__open-source-north-dashboards.yaml` and copies the repository spec into the same directory. This `generated/` folder remains `.gitignore`d so secrets never land in git.
- `make grafana-up` depends on `git-sync-secrets`, so every boot regenerates the manifests before `docker compose up -d` runs. If you want Grafana to ingest those manifests, run the helper script after Grafana is healthy, e.g.:
  ```bash
  BOOTSTRAP_DIR="$(pwd)/grafana/git-sync/generated" \
  GRAFANA_URL="http://localhost:3000" \
  sh grafana/git-sync/scripts/apply.sh
  ```
  The script mirrors what the curl sidecar previously did: it waits for the `/api/health` endpoint, then `PUT`s both the Connection and Repository objects to the provisioning API. No webhooks are configured—Grafana simply polls on the `spec.sync.intervalSeconds` cadence you set (300 seconds by default).
- If you later decide to enable webhook delivery or PR previews, update the template to include those fields and expose Grafana over HTTPS with `GF_SERVER_ROOT_URL` as advised in the Grafana documentation; otherwise the current pull-only setup is sufficient for periodically syncing dashboards from the GitHub App installation.
