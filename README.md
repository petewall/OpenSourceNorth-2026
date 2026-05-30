# Open Source North 2026

A live demo environment for an Open Source North 2026 talk, in which I demonstrated three dashboards:

* Game statistics for the 1990's game series Marathon
* A home mortgage burndown dashboard
* A home climate monitoring dashboard

Then, the presentation concludes with using an LLM to generate a dashboard from a [prompt](./dashboard-prompt.txt),
which is attempting to analyze talk performance against environmental data.

The slides are available here: [Slides.pdf](./Slides.pdf).

## Stack

These services run within Docker Compose:

* **Grafana** — dashboards and visualization (port 3000)
* **Prometheus** — metrics storage with remote-write enabled (port 9090)
* **Loki** — log aggregation (port 3100)
* **MongoDB** — backing store for the Marathon dashboards (port 27017)
* **OpenTelemetry Collector** — scrapes the host's CO2 exporter and Talkbox,
  forwards metrics to Prometheus and logs to Loki

Utilities running concurrently, but outside the Docker Compose stack:

* **CO2 Exporter** - Generates metrics from CO2 and temperature readings ([source](https://github.com/petewall/CO2MeterExporter/)). 
* **Talkbox** - Runs a local LLM model to create a transcript, including filler words. Also generates metrics for the
  words per minute and filler word counts ([source](https://github.com/petewall/talkbox)). 

If you are trying to run this yourself, the demos might work because you would not have access to the same dashboard
data that I do.

## Usage

```sh
make start    # bring up the docker compose stack
make prep     # seed databases and push Grafana resources
make stop     # tear down
make purge    # tear down and wipe volumes
```

Run `make help` for the full target list.
