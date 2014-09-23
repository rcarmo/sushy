BUNDLE=sushy.zip

repl:
	PYTHONPATH=$(BUNDLE) hy

deps:
	pip install -r requirements.txt

clean:
	rm -f *.zip
	rm -f sushy/*.pyc

bundle:
	hyc sushy/*.hy
	zip -r9 $(BUNDLE) . -i *.py *.pyc

test-bundle:
	PYTHONPATH=$(BUNDLE) python -m sushy
