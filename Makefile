# Academic paper build system
# Run 'make' with no arguments to see help.
# Tip: 'make -j N <targets>' builds independent targets in parallel.

.DEFAULT_GOAL := help

# ── Configuration (overridden by .env) ────────────────────────────────────────
-include .env
export
MAKEFLAGS += -j$(JOBS)

PAPER_NAME       ?= main
BUILD_DIR        ?= build
VERSION_FILE     ?= .version
DRAFTS_DIR       ?= drafts
AUTOCLEAN        ?= false
CLEAN_EXTENSIONS ?= aux log out bbl blg synctex.gz toc spl fls fdb_latexmk

# style/ holds journal .cls/.sty/.bst files; LaTeX finds them automatically.
export TEXINPUTS := ./style//:$(TEXINPUTS)
export BSTINPUTS := ./style//:$(BSTINPUTS)

LATEX  = pdflatex -interaction=nonstopmode -halt-on-error
BIBTEX = bibtex
DEPS   = preamble.tex body.tex references.bib \
         $(wildcard sections/*.tex) $(wildcard figures/*.tex)

# ── Version ───────────────────────────────────────────────────────────────────
_vmajor = $(shell cut -d. -f1 $(VERSION_FILE) 2>/dev/null || echo 1)
_vminor = $(shell cut -d. -f2 $(VERSION_FILE) 2>/dev/null || echo 0)

.PHONY: help pdf draft bump set-major set-minor submit clean distclean \
        config set setup init pages _build _autoclean _version

# ── Help ──────────────────────────────────────────────────────────────────────
help:
	@printf '\033[1mAcademic paper build system\033[0m\n'
	@printf 'Paper: \033[36m$(PAPER_NAME)\033[0m   Version: \033[33mv$(_vmajor).$(_vminor)\033[0m\n\n'
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@printf '\nSource: \033[2mmain.tex\033[0m   Build: \033[2m$(BUILD_DIR)/\033[0m   Output: \033[2m$(PAPER_NAME).pdf\033[0m\n'
	@printf 'Tip: \033[2mmake -j N <targets>\033[0m builds independent targets in parallel.\n'

# ── Configuration display and editing ─────────────────────────────────────────
config: ## Show all settings and their current values
	@printf '\033[1mCurrent configuration\033[0m  (edit \033[2m.env\033[0m or use \033[2mmake set KEY=... VALUE=...\033[0m)\n\n'
	@printf '  \033[36m%-22s\033[0m %s\n' 'PAPER_NAME'       '$(PAPER_NAME)'
	@printf '  \033[36m%-22s\033[0m %s\n' 'BUILD_DIR'        '$(BUILD_DIR)'
	@printf '  \033[36m%-22s\033[0m %s\n' 'DRAFTS_DIR'       '$(DRAFTS_DIR)'
	@printf '  \033[36m%-22s\033[0m %s\n' 'VERSION_FILE'     '$(VERSION_FILE)'
	@printf '  \033[36m%-22s\033[0m %s\n' 'JOBS'             '$(JOBS)'
	@printf '  \033[36m%-22s\033[0m %s\n' 'AUTOCLEAN'        '$(AUTOCLEAN)'
	@printf '  \033[36m%-22s\033[0m %s\n' 'CLEAN_EXTENSIONS' '$(CLEAN_EXTENSIONS)'
	@printf '\n  \033[33m%-22s\033[0m v$(_vmajor).$(_vminor)\n' 'VERSION'

set: ## Edit a .env setting: make set KEY=AUTOCLEAN VALUE=true
	@python3 -c "\
import re, pathlib; \
key, val = '$(KEY)', '$(VALUE)'; \
p = pathlib.Path('.env'); \
t = p.read_text(); \
updated = re.sub(r'^' + re.escape(key) + r'=.*', key + '=' + val, t, flags=re.M); \
p.write_text(updated if updated != t else t + key + '=' + val + '\n'); \
print('  [config]  ' + key + '=' + val)"

# ── PDF: bump minor, build (no archive) ──────────────────────────────────────
pdf: ## Bump minor version, build with watermark (no archive)
	@set -e; \
	MAJOR=$$(cut -d. -f1 $(VERSION_FILE)); \
	MINOR=$$(cut -d. -f2 $(VERSION_FILE)); \
	MINOR=$$((MINOR + 1)); \
	echo "$$MAJOR.$$MINOR" > $(VERSION_FILE); \
	printf '\\usepackage{draftwatermark}\n\\SetWatermarkText{\\textbf{DRAFT v%s.%s}}\n\\SetWatermarkAngle{45}\n\\SetWatermarkScale{1}\n\\SetWatermarkLightness{0.78}\n' $$MAJOR $$MINOR > version.tex; \
	echo "  [version] v$$MAJOR.$$MINOR"; \
	$(MAKE) --no-print-directory _build; \
	$(MAKE) --no-print-directory _autoclean

# All artefacts go to BUILD_DIR; PDF is copied to root on completion.
_build:
	@mkdir -p $(BUILD_DIR)
	$(LATEX) -output-directory=$(BUILD_DIR) main.tex
	-$(BIBTEX) $(BUILD_DIR)/main
	$(LATEX) -output-directory=$(BUILD_DIR) main.tex
	$(LATEX) -output-directory=$(BUILD_DIR) main.tex
	@cp $(BUILD_DIR)/main.pdf $(PAPER_NAME).pdf

# ── Draft: bump minor, build, archive ────────────────────────────────────────
draft: ## Bump minor version, build with watermark, archive to drafts/
	@set -e; \
	MAJOR=$$(cut -d. -f1 $(VERSION_FILE)); \
	MINOR=$$(cut -d. -f2 $(VERSION_FILE)); \
	MINOR=$$((MINOR + 1)); \
	echo "$$MAJOR.$$MINOR" > $(VERSION_FILE); \
	printf '\\usepackage{draftwatermark}\n\\SetWatermarkText{\\textbf{DRAFT v%s.%s}}\n\\SetWatermarkAngle{45}\n\\SetWatermarkScale{1}\n\\SetWatermarkLightness{0.78}\n' $$MAJOR $$MINOR > version.tex; \
	echo "  [version] v$$MAJOR.$$MINOR"; \
	$(MAKE) --no-print-directory _build; \
	mkdir -p $(DRAFTS_DIR); \
	cp $(PAPER_NAME).pdf $(DRAFTS_DIR)/$(PAPER_NAME)-v$$MAJOR.$$MINOR.pdf; \
	echo "  [draft]   $(DRAFTS_DIR)/$(PAPER_NAME)-v$$MAJOR.$$MINOR.pdf"

# ── Version management ────────────────────────────────────────────────────────
bump: ## Increment major version, reset minor to 0: make bump
	@MAJOR=$$(cut -d. -f1 $(VERSION_FILE)); \
	 MAJOR=$$((MAJOR + 1)); \
	 echo "$$MAJOR.0" > $(VERSION_FILE); \
	 echo "  [version] v$$MAJOR.0"

set-major: ## Set major version to N: make set-major N=2
	@MINOR=$$(cut -d. -f2 $(VERSION_FILE)); \
	 echo "$(N).$$MINOR" > $(VERSION_FILE); \
	 echo "  [version] v$(N).$$MINOR"

set-minor: ## Set minor version to N: make set-minor N=7
	@MAJOR=$$(cut -d. -f1 $(VERSION_FILE)); \
	 echo "$$MAJOR.$(N)" > $(VERSION_FILE); \
	 echo "  [version] v$$MAJOR.$(N)"

# ── Submit: build without watermark ──────────────────────────────────────────
submit: ## Build clean copy without draft watermark (for submission)
	@rm -f version.tex
	@$(MAKE) --no-print-directory _build
	@echo "  [submit]  $(PAPER_NAME).pdf — no watermark, source is main.tex"

# ── Clean ─────────────────────────────────────────────────────────────────────
clean: ## Remove build dir and artefacts (keep PDF and drafts)
	@rm -rf $(BUILD_DIR) version.tex page-*.png
	@echo "  [clean]   done"

distclean: clean ## Remove build dir, artefacts, and PDF
	@rm -f $(PAPER_NAME).pdf
	@echo "  [distclean] done"

_autoclean:
ifeq ($(AUTOCLEAN),true)
	@$(MAKE) --no-print-directory clean
endif

# ── Rasterise pages ───────────────────────────────────────────────────────────
pages: ## Rasterise PDF pages to page-*.png (build pdf first; requires poppler)
	pdftoppm -r 100 $(PAPER_NAME).pdf page -png

# ── Platform setup ────────────────────────────────────────────────────────────
UNAME_S := $(shell uname -s 2>/dev/null || echo Windows_NT)

setup: ## Install LaTeX tools for your platform
ifeq ($(UNAME_S),Darwin)
	@echo "macOS: installing BasicTeX via Homebrew Cask, then tlmgr packages"
	brew install --cask basictex
	@eval "$$(/usr/libexec/path_helper)" && sudo tlmgr update --self && \
	  sudo tlmgr install latexmk draftwatermark booktabs hyperref cleveref natbib xurl
else ifeq ($(UNAME_S),Linux)
	@echo "Linux: installing texlive-full via apt"
	sudo apt-get update && sudo apt-get install -y texlive-full latexmk
else
	@echo "Windows — install MiKTeX via winget:"
	@echo "  winget install MiKTeX.MiKTeX"
	@echo "Then open MiKTeX Console (Package Manager) and install:"
	@echo "  draftwatermark booktabs hyperref cleveref natbib"
endif

# ── Git init ──────────────────────────────────────────────────────────────────
init: ## Initialise git repo for this paper (run once)
	@if [ -d .git ]; then \
	  echo "  [git] already initialised"; \
	else \
	  git init -q && git add . && git commit -q -m "Initial scaffold: $(PAPER_NAME)"; \
	  echo "  [git] initialised and committed"; \
	fi
