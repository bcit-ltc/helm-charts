# Rooted at repo top (where charts/ lives)
CHARTS_DIR := charts
LIB_NAME   := app-common
LIB_DIR    := $(CHARTS_DIR)/$(LIB_NAME)
# All app charts except the library
APP_DIRS   := $(shell find $(CHARTS_DIR) -mindepth 1 -maxdepth 1 -type d ! -name $(LIB_NAME) | sort)
# All chart directories (library + apps) for docs generation
CHART_DIRS := $(LIB_DIR) $(APP_DIRS)
DIST_DIR   := .cr-release-packages



.PHONY: help
help:
	@echo "Targets:"
	@echo "  lint            Lint all charts"
	@echo "  deps            helm dependency update on all app charts"
	@echo "  package-lib     Package library chart to $(DIST_DIR)/"
	@echo "  package-apps    Package app charts to $(DIST_DIR)/ (after deps)"
	@echo "  docs            Regenerate README.md for each chart using helm-docs"
	@echo "  clean-dist      Remove $(DIST_DIR)/"

$(DIST_DIR):
	mkdir -p $@

TMPDIR := $(CURDIR)/.tmp
export TMPDIR

.PHONY: lint
lint: deps
	@mkdir -p .tmp
	@TMPDIR=$(CURDIR)/.tmp; export TMPDIR; \
	for c in $(APP_DIRS); do \
	  echo "==> helm lint $$c"; \
	  helm lint $$c --with-subcharts || exit $$?; \
	done
	@rm -rf .tmp

.PHONY: deps
deps:
	@mkdir -p .tmp
	@TMPDIR=$(CURDIR)/.tmp; export TMPDIR; \
	for c in $(APP_DIRS); do \
	  echo "==> helm dependency update $$c"; \
	  helm dependency update $$c || exit $$?; \
	done
	@rm -rf .tmp

.PHONY: package-lib
package-lib: $(DIST_DIR)
	@mkdir -p .tmp
	@TMPDIR=$(CURDIR)/.tmp; export TMPDIR; \
	echo "==> Packaging $(LIB_DIR)"; \
	helm package $(LIB_DIR) -d $(DIST_DIR)
	@rm -rf .tmp

.PHONY: package-apps
package-apps: deps $(DIST_DIR)
	@mkdir -p .tmp
	@TMPDIR=$(CURDIR)/.tmp; export TMPDIR; \
	for c in $(APP_DIRS); do \
	  echo "==> Packaging $$c"; \
	  helm package $$c -d $(DIST_DIR) || exit $$?; \
	done
	@rm -rf .tmp

.PHONY: docs
docs:
	@for c in $(APP_DIRS); do \
	  echo "==> Generating docs in $$c"; \
	  (cd $$c && docker run -it --volume "$$(pwd):/helm-docs" -u $$(id -u) \
	    jnorwood/helm-docs:latest \
	    helm-docs --template-files=./files/_README.md.gotmpl) || exit $$?; \
	done

.PHONY: clean-dist
clean-dist:
	rm -rf $(DIST_DIR)
