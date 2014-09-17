BUNDLE=sushy.zip

clean:
	rm -f *.zip
	rm -f sushy/*.pyc

bundle:
	hyc sushy/*.hy
	zip -r9 $(BUNDLE) . -i *.py *.pyc

test-bundle:
	PYTHONPATH=$(BUNDLE) python -m sushy
