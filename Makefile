BUNDLE=sushy.zip
HYFILES=sushy/*.hy
PYFILES=sushy/*.py

repl:
	PYTHONPATH=$(BUNDLE) hy

deps:
	pip install -r requirements.txt

clean:
	rm -f *.zip
	rm -f sushy/*.pyc

bundle: $(HYFILES) $(PYFILES)
	hyc $(HYFILES)
	zip -r9 $(BUNDLE) . -i *.py *.pyc

serve: bundle
	PYTHONPATH=$(BUNDLE) CONTENT_PATH=pages STATIC_PATH=static python -m sushy
