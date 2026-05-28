# Open Source North 2026

A live demo environment for an Open Source North 2026 talk, showing a full local
observability stack with Grafana, Prometheus, Loki, and an OpenTelemetry Collector
ingesting metrics and logs from a CO2 sensor and a "talkbox" speech analyzer.

Link to slides coming soon!

## Stack

- **Grafana** — dashboards and visualization (port 3000)
- **Prometheus** — metrics storage with remote-write enabled (port 9090)
- **Loki** — log aggregation (port 3100)
- **MongoDB** — backing store for the Marathon dashboards (port 27017)
- **OpenTelemetry Collector** — scrapes the host's CO2 exporter and Talkbox,
  forwards metrics to Prometheus and logs to Loki

## Usage

```sh
make start    # bring up the docker compose stack
make prep     # seed databases and push Grafana resources
make stop     # tear down
make purge    # tear down and wipe volumes
```

Run `make help` for the full target list.
