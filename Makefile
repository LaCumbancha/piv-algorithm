SHELL := /bin/bash
PWD := $(shell pwd)
PYTHON := /usr/local/bin/python3 -W ignore

version = "SNAPSHOT"

clean:
	@rm -rf ./build/
	@rm -rf ./dist/
	@rm -rf ./piv_algorithm.egg-info/
.PHONY: clean

build: clean
	@$(SHELL) ./extras/scripts/update-release $(version)
	@$(PYTHON) -m pip install build
	@$(PYTHON) -m build --wheel
.PHONY: system-up

release: build
	git add .
	git ci -m "Releasing version $(version)"
	git push
	git tag $(version)
	git push --tags
.PHONY: release

test:
	@$(PYTHON) ./test.py
.PHONY: system-up
