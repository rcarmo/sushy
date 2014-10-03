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

build: $(HYFILES) $(PYFILES)
	hyc $(HYFILES)
	#zip -r9 $(BUNDLE) sushy/* -i *.py *.pyc
	#rm -f sushy/*.pyc

serve: build
	CONTENT_PATH=pages STATIC_PATH=static python -m sushy.app
