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

%.pyc: %.hy
	hyc $<

build: $(BYTECODE)

bundle: $(HYFILES) $(PYFILES)
	zip -r9 $(BUNDLE) sushy/* -i *.py *.pyc
	rm -f sushy/*.pyc

serve: build
	CONTENT_PATH=pages STATIC_PATH=static python -m sushy.app
