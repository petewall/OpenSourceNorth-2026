# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This is a demo/presentation repository for a talk "Building Real-World Grafana Dashboards" at Open Source North 2026. It contains:
- A Grafana sandbox environment (Docker Compose with Git Sync)
- A browser-based slide deck server that embeds live Grafana dashboards
- Data generation scripts for demo datasets

## Common Commands

### Start everything
```bash
make start           # Start both Grafana and presentation server
make start-grafana   # Start only Grafana (Docker Compose on port 3000)
make start-presentation  # Start only the slide server (port 8080)
make stop-grafana    # Tear down Grafana Docker stack
```

### Grafana secrets (requires 1Password CLI)
```bash
cd grafana && make   # Generates provisioning/datasources/datasources.yaml and resources/connection.yaml from 1Password secrets
```

### Presentation server
```bash
cd presentation && npm install  # Install dependencies
cd presentation && npm start    # Start server (http://localhost:8080)
cd presentation && npm run dev  # Start in development mode
```

### Generate mortgage demo data
```bash
python3 scripts/generate_mortgage_data.py [options]
# Key options: --principal, --annual-rate, --term-years, --base-payment, --escrow, --extra-principal N:AMOUNT, --start-date, --output
# Example: python3 scripts/generate_mortgage_data.py --principal 323669.67 --annual-rate 0.045 --base-payment 2000 --escrow 848.18
```

## Architecture

### Grafana Environment (`grafana/`)
- `docker-compose.yml`: Runs Grafana (main branch image) with anonymous access on port 3000. Plugins: `grafana-googlesheets-datasource`, `yesoreyeram-infinity-datasource`. Feature flags enable `provisioning` and `kubernetesDashboards` for Git Sync.
- **Git Sync**: Grafana syncs dashboards from `grafana/dashboards/` in this repo via the Kubernetes-style Repository CRD (`repository.yaml`). The sync connection requires GitHub App credentials rendered from `templates/connection.yaml` via `envsubst`.
- `Makefile`: Uses `op read` (1Password CLI) to inject secrets into datasource and connection YAML files. Requires env vars: `GITHUB_APP_ID`, `GITHUB_INSTALL_ID`, `GITHUB_PRIVATE_KEY`.
- `provisioning/datasources/datasources.yaml` and `resources/connection.yaml` are git-ignored (contain credentials).

### Presentation Server (`presentation/`)
- Express 5 server (`server.js`) serving a single-page app on port 8080.
- `GET /api/slides` returns `slides.json`; all other routes serve `public/index.html`.
- Slides defined in `slides.json` as an array with `type: "content"` (bullet points) or `type: "iframe"` (embedded URLs, typically Grafana dashboards).
- Frontend is vanilla JS (`public/app.js`) with keyboard navigation (←/→/Space) and fullscreen support.

### Data (`MortgageData.csv`, `scripts/`)
- `scripts/generate_mortgage_data.py`: Generates synthetic mortgage amortization CSV used for the mortgage dashboard demo. Output goes to `MortgageData.csv` at repo root by default.

### Dashboard Content
- Dashboards live in `grafana/dashboards/` and are synced to Grafana via Git Sync (300s interval).
- Three demo dashboards: house (Home Assistant data via Prometheus), mortgage (Google Sheets), marathon (MongoDB).
