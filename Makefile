# Rooted at repo top (where charts/ lives)
CHARTS_DIR := charts
LIB_NAME   := app-common
LIB_DIR    := $(CHARTS_DIR)/$(LIB_NAME)
# All app charts except the library
APP_DIRS   := $(shell find $(CHARTS_DIR) -mindepth 1 -maxdepth 1 -type d ! -name $(LIB_NAME) | sort)
DIST_DIR   := .cr-release-packages

.PHONY: help
help:
	@echo "Targets:"
	@echo "  lint            Lint all charts"
	@echo "  deps            helm dependency update on all app charts"
	@echo "  package-lib     Package library chart to $(DIST_DIR)/"
	@echo "  package-apps    Package app charts to $(DIST_DIR)/ (after deps)"
	@echo "  clean-dist      Remove $(DIST_DIR)/"

$(DIST_DIR):
	mkdir -p $@

.PHONY: lint
lint: deps
	@helm lint $(LIB_DIR) || true
	@for c in $(APP_DIRS); do \
	  echo "==> helm lint $$c"; \
	  helm lint $$c --with-subcharts || exit $$?; \
	done

.PHONY: deps
deps:
	@for c in $(APP_DIRS); do \
	  echo "==> helm dependency update $$c"; \
	  helm dependency update $$c || exit $$?; \
	done

.PHONY: package-lib
package-lib: $(DIST_DIR)
	@echo "==> Packaging $(LIB_DIR)"
	helm package $(LIB_DIR) -d $(DIST_DIR)

.PHONY: package-apps
package-apps: deps $(DIST_DIR)
	@for c in $(APP_DIRS); do \
	  echo "==> Packaging $$c"; \
	  helm package $$c -d $(DIST_DIR) || exit $$?; \
	done

.PHONY: clean-dist
clean-dist:
	rm -rf $(DIST_DIR)
