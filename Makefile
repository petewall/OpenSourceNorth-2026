#CONNECTION_TEMPLATE := grafana/templates/connection.yaml
#CONNECTION_OUTPUT := grafana/provisioning/resources/connection.yaml
#
#.PHONY: grafana-secrets
### Generate Grafana provisioning secrets (requires 1Password CLI)
#grafana-secrets: $(CONNECTION_OUTPUT)
#
#$(CONNECTION_OUTPUT): $(CONNECTION_TEMPLATE) | grafana/provisioning/resources
#	GITHUB_PAT="$$(op read 'op://Lab/Open Source North 2026 PAT/password')" && \
#	export GITHUB_PAT && \
#	yq eval '.secure.token.create = strenv(GITHUB_PAT)' $< > $@
#	@echo "[grafana] wrote $@"

grafana/provisioning/datasources/datasources.yaml: grafana/templates/datasources.yaml
	@mkdir -p $(shell dirname $@)
	yq eval ' \
		(.datasources[] | select(.name == "Google Sheets")).jsonData.clientEmail = strenv(GCP_CLIENT_EMAIL) | \
		(.datasources[] | select(.name == "Google Sheets")).jsonData.defaultProject = strenv(GCP_PROJECT) | \
		(.datasources[] | select(.name == "Google Sheets")).secureJsonData.privateKey = strenv(GCP_SERVICE_ACCOUNT_TOKEN) \
	  ' $< > $@

.PHONY: grafana-secrets
grafana-secrets: grafana/provisioning/datasources/datasources.yaml

.PHONY: start
start:
	docker compose up -d

.PHONY: stop
stop:
	docker compose down

.PHONY: copy-password
copy-password:
	@echo "$${GRAFANA_PASSWORD}" | pbcopy

.PHONY: copy-prompt
copy-prompt:
	@cat dashboard-prompt.txt | pbcopy

.PHONY: clean
clean:
	rm grafana/provisioning/datasources/datasources.yaml

.PHONY: purge
purge: stop
	docker compose down -v

