BUNDLE=sushy.zip
HYFILES=$(wildcard sushy/*.hy)
PYFILES=$(wildcard sushy/*.py)
BYTECODE=$(HYFILES:.hy=.pyc)

repl:
	PYTHONPATH=$(BUNDLE) hy

deps:
	pip install -r requirements.txt

clean:
	rm -f *.zip
	rm -f $(BYTECODE)

# Turn Hy files into bytecode so that we can use a standard Python interpreter
%.pyc: %.hy
	hyc $<

build: $(BYTECODE)

# Experimental bundle to see if we can deploy this solely as a ZIP file
bundle: $(HYFILES) $(PYFILES)
	zip -r9 $(BUNDLE) sushy/* -i *.py *.pyc
	rm -f sushy/*.pyc

# Run with the embedded web server
serve: build
	BIND_ADDRESS=0.0.0.0 HTTP_PORT=8080 CONTENT_PATH=pages STATIC_PATH=static python -m sushy.app
