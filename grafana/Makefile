provisioning/datasources/datasources.yaml: templates/datasources.yaml
	@mkdir -p $(shell dirname $@)
	PROM_URL="$$(op read 'op://Lab/Grafana Cloud Metrics/website')/api/prom" && \
	PROM_USER="$$(op read 'op://Lab/Grafana Cloud Metrics/username')" && \
	PROM_PASS="$$(op read 'op://Lab/Grafana Cloud Metrics/password')" && \
	GS_CLIENT_EMAIL="$$(op read 'op://Lab/GCP Grafana Cloud Service Account/username')" && \
	GS_PROJECT="$$(op read 'op://Lab/GCP Grafana Cloud Service Account/notes' | jq -r '.project_id')" && \
	GS_PRIVATE_KEY="$$(op read 'op://Lab/GCP Grafana Cloud Service Account/notes' | jq -r '.private_key')" && \
	export PROM_URL PROM_USER PROM_PASS GS_CLIENT_EMAIL GS_PROJECT GS_PRIVATE_KEY && \
	yq eval ' \
	  .datasources[0].url = strenv(PROM_URL) | \
	  .datasources[0].basicAuthUser = strenv(PROM_USER) | \
	  .datasources[0].secureJsonData.basicAuthPassword = strenv(PROM_PASS) | \
	  .datasources[1].jsonData.clientEmail = strenv(GS_CLIENT_EMAIL) | \
	  .datasources[1].jsonData.defaultProject = strenv(GS_PROJECT) | \
	  .datasources[1].secureJsonData.privateKey = strenv(GS_PRIVATE_KEY) \
	' $< > $@
