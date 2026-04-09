GIT_SYNC_GENERATED := grafana/git-sync/generated
CONNECTION_TEMPLATE := grafana/git-sync/connection.template.yaml
CONNECTION_OUTPUT := grafana/git-sync/generated/default__connection__open-source-north-dashboards.yaml
REPOSITORY_SOURCE := grafana/git-sync/repositories/open-source-north-dashboards.yaml
REPOSITORY_OUTPUT := grafana/git-sync/generated/default__repository__open-source-north-dashboards.yaml
REQUIRED_GIT_SYNC_ENV := GITHUB_APP_ID GITHUB_INSTALL_ID GITHUB_PRIVATE_KEY

.PHONY: git-sync-secrets
## Generate Git Sync manifests by substituting environment variables into the connection template
## and copying the repository spec into the generated directory.
git-sync-secrets: $(CONNECTION_OUTPUT) $(REPOSITORY_OUTPUT)

$(CONNECTION_OUTPUT): $(CONNECTION_TEMPLATE) check-git-sync-env | $(GIT_SYNC_GENERATED)
	@envsubst < $< > $@
	@echo "[git-sync] wrote $@"

$(REPOSITORY_OUTPUT): $(REPOSITORY_SOURCE) | $(GIT_SYNC_GENERATED)
	@cp $< $@
	@echo "[git-sync] copied repository spec to $@"

$(GIT_SYNC_GENERATED):
	@mkdir -p $@

.PHONY: check-git-sync-env
check-git-sync-env:
	@$(foreach var,$(REQUIRED_GIT_SYNC_ENV),$(if $(value $(var)),,$(error Environment variable $(var) is required)))

.PHONY: git-sync-clean
## Remove generated Git Sync manifests
git-sync-clean:
	rm -f $(GIT_SYNC_GENERATED)/*.yaml

.PHONY: start-grafana
## Generate secrets and start Grafana stack
start-grafana: git-sync-secrets
	cd grafana && docker compose up -d

.PHONY: start-presentation
## Start the presentation server (petewall/slides via Docker)
start-presentation:
	docker run --rm -d --name slides -p 8080:3000 -v $(CURDIR)/presentation:/content ghcr.io/petewall/slides

.PHONY: stop-presentation
## Stop the presentation server
stop-presentation:
	docker stop slides

.PHONY: start
## Start Grafana and the presentation stack
start: start-grafana start-presentation

.PHONY: stop-grafana
## Stop Grafana stack
stop-grafana:
	cd grafana && docker compose down
