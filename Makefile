SHELL := /bin/bash
PWD := $(shell pwd)
PYTHON := /usr/local/bin/python3 -W ignore

release = "0.0.1"

clean:
	@rm -rf ./build/
	@rm -rf ./dist/
	@rm -rf ./piv_algorithm.egg-info/
.PHONY: clean

build: clean
	@$(SHELL) ./extras/scripts/update-release $(release)
	@$(PYTHON) -m pip install build
	@$(PYTHON) -m build --wheel
.PHONY: system-up

test:
	@$(PYTHON) ./test.py
.PHONY: system-up
