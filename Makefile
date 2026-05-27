##@ Grafana Artifacts

grafana/resources/repository.yaml: grafana/templates/repository.yaml ## Create the Git Sync repository
	@mkdir -p $(shell dirname $@)
	export GITHUB_PAT="$$(op read 'op://Lab/Open Source North 2026 PAT/password')" && \
	yq eval '.secure.token.create = strenv(GITHUB_PAT)' $< > $@

grafana/provisioning/datasources/datasources.yaml: grafana/templates/datasources.yaml
	@mkdir -p $(shell dirname $@)
	export GC_METRICS_URL="$$(op read "op://Lab/Grafana Cloud Metrics/website")/api/prom" && \
	export GC_METRICS_USERNAME=$$(op read "op://Lab/Grafana Cloud Metrics/username") && \
	export GC_METRICS_PASSWORD=$$(op read "op://Lab/Grafana Cloud Metrics/password") && \
	export GCP_CLIENT_EMAIL=$$(op read "op://Lab/GCP Grafana Cloud Service Account/notes" | jq -r '.client_email') && \
	export GCP_PROJECT=$$(op read "op://Lab/GCP Grafana Cloud Service Account/notes" | jq -r '.project_id') && \
	export GCP_PRIVATE_KEY=$$(op read "op://Lab/GCP Grafana Cloud Service Account/notes" | jq -r '.private_key') && \
	export MONGODB_URL=$$(op read "op://Lab/Cloud DB User/website") && \
	export MONGODB_SCHEME=$$(echo "$$MONGODB_URL" | sed 's|://.*||') && \
	export MONGODB_HOST=$$(echo "$$MONGODB_URL" | sed 's|^[^:]*://||;s|/.*||') && \
	export MONGODB_USERNAME=$$(op read "op://Lab/Cloud DB User/username") && \
	export MONGODB_PASSWORD=$$(op read "op://Lab/Cloud DB User/password") && \
	yq eval ' \
		(.datasources[] | select(.name == "Grafana Cloud Prometheus")).url = strenv(GC_METRICS_URL) | \
		(.datasources[] | select(.name == "Grafana Cloud Prometheus")).basicAuthUser = strenv(GC_METRICS_USERNAME) | \
		(.datasources[] | select(.name == "Grafana Cloud Prometheus")).secureJsonData.basicAuthPassword = strenv(GC_METRICS_PASSWORD) | \
		(.datasources[] | select(.name == "Google Sheets")).jsonData.clientEmail = strenv(GCP_CLIENT_EMAIL) | \
		(.datasources[] | select(.name == "Google Sheets")).jsonData.defaultProject = strenv(GCP_PROJECT) | \
		(.datasources[] | select(.name == "Google Sheets")).secureJsonData.privateKey = strenv(GCP_PRIVATE_KEY) | \
		(.datasources[] | select(.name == "MongoDB")).jsonData.connectionStringScheme = strenv(MONGODB_SCHEME) | \
		(.datasources[] | select(.name == "MongoDB")).jsonData.host = strenv(MONGODB_HOST) | \
		(.datasources[] | select(.name == "MongoDB")).jsonData.username = strenv(MONGODB_USERNAME) | \
		(.datasources[] | select(.name == "MongoDB")).secureJsonData.password = strenv(MONGODB_PASSWORD) \
	  ' $< > $@

grafana/dashboards/house-climate.json: ../dashboards/house-climate.json
	jq '(.spec.variables[] | select(.spec.name == "datasource")).spec.current.text = "Grafana Cloud Prometheus" | \
		(.spec.variables[] | select(.spec.name == "datasource")).spec.current.value = "grafanacloudprom"' $< > $@

HOUSE_IMAGE="https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Neues_Rathaus_Hannover_2013.jpg/960px-Neues_Rathaus_Hannover_2013.jpg"
SPREADSHEET_ID="1wh4Qnfli2_g4D3lblFrxfqRge3sr_eegy4JCt6NnRDE"
grafana/dashboards/mortgage-progress.json: ../dashboards/mortgage-progress.json
	cp $< $@
	jq --arg url $(HOUSE_IMAGE) --arg sheet $(SPREADSHEET_ID) '\
			.spec.variables[1].spec.current.text=$$url |\
			.spec.variables[1].spec.current.value=$$url |\
			.spec.variables[1].spec.query=$$url \
		' $@ > $@.updated && mv $@.updated $@
	sed -e 's/"spreadsheet": "[^"]*"/"spreadsheet": $(SPREADSHEET_ID)/' $@ > $@.updated && mv $@.updated $@

grafana/dashboards/Marathon/game.json: ../dashboards/marathon/game.json scripts/to_oss_mongodb.py
	python3 scripts/to_oss_mongodb.py < $< > $@

grafana/dashboards/Marathon/level.json: ../dashboards/marathon/level.json scripts/to_oss_mongodb.py
	python3 scripts/to_oss_mongodb.py < $< > $@

copy-dashboards: grafana/dashboards/house-climate.json grafana/dashboards/mortgage-progress.json grafana/dashboards/Marathon/game.json grafana/dashboards/Marathon/level.json ## Copy dashboards from my personal repository

.PHONY: clean
clean: ## Remove generated files
	rm -rf data
	rm grafana/provisioning/datasources/datasources.yaml
	rm grafana/resources/repository.yaml

##@ Test Data

FAKE_HOME_VALUE=500000
FAKE_MORTGAGE_AMOUNT=350000
FAKE_MORTGAGE_RATE=0.045
data/mortgage-burndown.csv:
	@mkdir -p $(shell dirname $@)
	python3 scripts/generate_mortgage_data.py \
		--start-date 2020-01-01 \
		--principal $(FAKE_MORTGAGE_AMOUNT) \
		--annual-rate $(FAKE_MORTGAGE_RATE) \
		--extra-principal 18:1000 \
		--extra-principal 24:1000 \
		--extra-principal 36:1000 \
		--extra-principal 48:1000 \
		--extra-principal 128:1000 \
		> $@

data/mortgage-details.csv:
	@mkdir -p $(shell dirname $@)
	echo "Original Amount,Interest Rate,Current Home Value" > $@
	echo "$(FAKE_MORTGAGE_AMOUNT),$(FAKE_MORTGAGE_RATE),$(FAKE_HOME_VALUE)" >> $@

.PHONY: mortgage-data
mortgage-data: data/mortgage-burndown.csv data/mortgage-details.csv ## Generate fake mortgage data

data/pg/seeds/users.sql: ../ironwall/seeds/users.sql
	@mkdir -p $(shell dirname $@)
	cp $< $@

data/pg/seeds/tags.sql: ../ironwall/seeds/tags.sql
	@mkdir -p $(shell dirname $@)
	cp $< $@

data/pg/seeds/exercises.sql: ../ironwall/seeds/exercises.sql
	@mkdir -p $(shell dirname $@)
	cp $< $@

data/pg/seeds/workouts.sql: ../ironwall/seeds/workouts.sql
	@mkdir -p $(shell dirname $@)
	cp $< $@

data/pg/seeds/fitbod.sql: ../ironwall/seeds/fitbod.sql
	@mkdir -p $(shell dirname $@)
	cp $< $@

postgres/migrations/001_init.sql: ../ironwall/db/migrations/001_init.sql
	@mkdir -p $(shell dirname $@)
	cp $< $@

pg-seeds: data/pg/seeds/users.sql data/pg/seeds/tags.sql data/pg/seeds/exercises.sql data/pg/seeds/workouts.sql data/pg/seeds/fitbod.sql

##@ Local Instance
.PHONY: start
start: grafana/provisioning/datasources/datasources.yaml postgres/migrations/001_init.sql ## Start the local services
	docker compose up -d
	@sleep 1
	gcx config check

.PHONY: prep
prep: start grafana/resources/repository.yaml pg-seeds ## Seed the databases after startup
	# Push the Git Sync repository
	gcx resources push --path grafana/resources
	# Seed the PostgreSQL database
	psql "$${POSTGRES_URL}" -f data/pg/seeds/users.sql
	psql "$${POSTGRES_URL}" -f data/pg/seeds/tags.sql
	psql "$${POSTGRES_URL}" -f data/pg/seeds/exercises.sql
	psql "$${POSTGRES_URL}" -f data/pg/seeds/fitbod.sql
	psql "$${POSTGRES_URL}" -f data/pg/seeds/workouts.sql

.PHONY: check
check:
	@echo "Checking CO2 metrics exporter..." && curl http://localhost:9800
	@echo "Checking Talkbox exporter..." && curl http://localhost:9186
	@echo "Checking Talkbox logs..." && test -s ../talkbox/logs/debug.txt && echo "OK" || echo "WARN: debug.txt is empty or missing"
	@echo "Checking Talkbox transcript..." && test -s ../talkbox/logs/transcript.txt && echo "OK" || echo "WARN: transcript.txt is empty or missing"
	@echo "Checking gcx..." && gcx config check

.PHONY: stop
stop: ## Stop the local services
	docker compose down

.PHONY: purge
purge: stop ## Stop the local services and delete local storage
	docker compose down -v

.PHONY: copy-password
copy-password: ## Copy the Grafana admin password
	@echo "$${GRAFANA_PASSWORD}" | pbcopy

##@ AI

.PHONY: start-claude
start-claude: ## Start Claude in preparation for creating the AI-generated dashboard
	claude --model sonnet --effort medium

.PHONY: copy-prompt
copy-prompt: ## Copy the prompt for creating the AI-generated dashboard
	@cat dashboard-prompt.txt | pbcopy

##@ General

# The help target prints out all targets with their descriptions organized
# beneath their categories. The categories are represented by '##@' and the
# target descriptions by '##'. The awk commands is responsible for reading the
# entire set of makefiles included in this invocation, looking for lines of the
# file as xyz: ## something, and then pretty-format the target and help. Then,
# if there's a line with ##@ something, that gets pretty-printed as a category.
# More info on the usage of ANSI control characters for terminal formatting:
# https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_parameters
# More info on the awk command:
# http://linuxcommand.org/lc3_adv_awk.php

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
