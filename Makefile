SHELL := /bin/bash
PWD := $(shell pwd)
PYTHON := /usr/local/bin/python3 -W ignore

release = "0.0.1"

build:
	@rm -rf ./build/
	@$(SHELL) ./extras/scripts/update-release $(release)
	@$(PYTHON) -m pip install build
	@$(PYTHON) -m build --wheel
.PHONY: system-up

test:
	@$(PYTHON) ./test.py
.PHONY: system-up
