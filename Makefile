# Set these if not defined already
export BIND_ADDRESS?=0.0.0.0
export PORT?=8080
export DEBUG?=False
export PROFILER?=False
export CONTENT_PATH?=pages
export THEME_PATH?=themes/blog
export DATABASE_PATH?=/tmp/sushy.db
export SITE_NAME?=Sushy
export PYTHONIOENCODING=UTF_8:replace
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export CURRENT_GIT_BRANCH?=`git symbolic-ref --short HEAD`

.DEFAULT_GOAL := help

# Experimental zip bundle
BUNDLE=sushy.zip
export PYTHONPATH=$(BUNDLE)

# Source code
HYFILES=$(wildcard sushy/*.hy)
PYFILES=$(wildcard sushy/*.py)
BYTECODE=$(HYFILES:.hy=.pyc)
PYTHONCODE=$(HYFILES:.hy=.py)
PROFILES=$(wildcard *.pstats)
CALL_DIAGRAMS=$(PROFILES:.pstats=.png)

repl: ## Start a Hy REPL
	hy -i "(import sushy.app)"

deps: ## Install Dependencies
	pip install -U --break-system-packages -r requirements.txt

deps-upgrade: ## Interactively upgrade requirements.txt
	pip-upgrade --skip-package-installation --skip-virtualenv-check requirements.txt

clean: ## Clean environment
	rm -f *.zip
	rm -rf sushy/__pycache__
	rm -f $(BYTECODE)
	rm -f $(PYTHONCODE)
	rm -f $(DATABASE_PATH)*

%.pyc: %.hy ## Turn Hy files into bytecode so that we can use a standard Python interpreter
	hyc $<

%.py: %.hy ## Turn Hy files into Python source so that PyPy will (eventually) be happy
	hy2py $< > $@

build: $(BYTECODE) 

bundle: $(HYFILES) $(PYFILES)  ## Experimental bundle to see if we can deploy this solely as a ZIP file
	zip -r9 $(BUNDLE) sushy/* -i *.py *.pyc
	rm -f sushy/*.pyc

serve: ## Run with the embedded web server
	hy -m sushy.app

uwsgi: build ## Run with uwsgi
	uwsgi --http :$(PORT) --python-path . --wsgi sushy.app --callable app -p 1

uwsgi-ini: build ## Run with uwsgi
	uwsgi --ini uwsgi.ini

index: ## Run indexer
	hy -m sushy.indexer

index-watch: ## Run indexer and watch for changes
	hy -m sushy.indexer watch

%.png: %.pstats ## Render pstats profiler files into nice PNGs (requires dot)
	python tools/gprof2dot.py -f pstats $< | dot -Tpng -o $@

profile: $(CALL_DIAGRAMS) ## Render profile

debug-%: ; @echo $*=$($*)

restart-production: ## Restart production Piku instance
	ssh piku@piku restart sushy

deploy-production: ## Push to production Piku instance
	git push production master

reset-production: ## Destroy production instance
	ssh piku@piku destroy sushy

redeploy: reset-production deploy-production restart-production ## Redeploy

deploy: deploy-production restart-production ## Deploy

help:
	@grep -hE '^[A-Za-z0-9_ \-]*?:.*##.*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
