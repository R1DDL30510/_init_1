SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ARCHIVE ?=
ENV_FILE := $(ROOT)/.env.local
TLS_DIR := $(ROOT)/secrets/tls
LOG_FILE := $(ROOT)/logs/shs.jsonl
ACCEPTANCE := $(ROOT)/tests/acceptance

.PHONY: bootstrap
bootstrap:
	mkdir -p $(TLS_DIR) logs ingest
	test -f $(ENV_FILE) || { cp $(ROOT)/.env.example $(ENV_FILE) && echo "Created $(ENV_FILE)."; }
	chmod 600 $(ENV_FILE)
	SHS_BASE=$${SHS_BASE:-$(ROOT)} SHS_DOMAIN=$${SHS_DOMAIN:-localhost} TLS_MODE=$${TLS_MODE:-local-ca} \
		bash $(ROOT)/scripts/tls/gen_local_ca.sh
	touch $(LOG_FILE)
	chmod 600 $(LOG_FILE)
	printf 'bootstrap complete\n'

.PHONY: up
up: guard-secrets
	docker compose --env-file $(ENV_FILE) up -d --remove-orphans
	$(MAKE) status

.PHONY: down
down:
	docker compose --env-file $(ENV_FILE) down --remove-orphans

.PHONY: test
test:
	@set -euo pipefail
	@mkdir -p $(dir $(LOG_FILE))
	@if [ ! -f $(LOG_FILE) ]; then \
		umask 177 && touch $(LOG_FILE); \
	fi
	: "$${SHS_DELETE_TARGET_URL:=https://example.invalid/delete-target}"
	: "$${SHS_DELETE_VALIDATION_URL:=https://example.invalid/delete-validate}"
	: "$${SHS_DELETE_RECORD_ID:=00000000-0000-0000-0000-000000000000}"
	export SHS_DELETE_TARGET_URL SHS_DELETE_VALIDATION_URL SHS_DELETE_RECORD_ID
	@for script in $$(ls $(ACCEPTANCE)/*.sh | sort); do \
		echo "Running $$script"; \
		SHS_ENV_FILE=$(ENV_FILE) bash $$script || exit $$?; \
	done

.PHONY: backup
backup: guard-secrets
	bash $(ROOT)/scripts/backup.sh

.PHONY: restore
restore: guard-secrets
	@if [ -z "$(ARCHIVE)" ]; then \
		echo "Set ARCHIVE=/path/to/archive" >&2; \
		exit 1; \
	fi
	bash $(ROOT)/scripts/restore.sh $(ARCHIVE)

.PHONY: ca.rotate
ca.rotate:
	rm -f $(TLS_DIR)/leaf.pem $(TLS_DIR)/leaf.key
	$(MAKE) bootstrap

.PHONY: clean
clean:
	rm -f $(ENV_FILE)
	rm -f $(TLS_DIR)/ca.* $(TLS_DIR)/leaf.*
	rm -f $(LOG_FILE)
	rmdir --ignore-fail-on-non-empty $(TLS_DIR) || true

.PHONY: status
status:
	bash $(ROOT)/scripts/status.sh

.PHONY: guard-secrets
guard-secrets:
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Missing $(ENV_FILE); run make bootstrap" >&2; \
		exit 1; \
	fi
	@if [ ! -f $(TLS_DIR)/ca.crt ] || [ ! -f $(TLS_DIR)/leaf.pem ]; then \
		echo "TLS assets missing; run make bootstrap" >&2; \
		exit 1; \
	fi
	@if grep -q '\*\*\*FILL\*\*\*' $(ENV_FILE); then \
		echo "Environment contains placeholders; update $(ENV_FILE)" >&2; \
		exit 1; \
	fi
