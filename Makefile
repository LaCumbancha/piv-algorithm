SHELL := /bin/bash
PWD := $(shell pwd)
PYTHON := /usr/local/bin/python3 -W ignore

build:
	@rm -rf build/
	@$(PYTHON) -m pip install build
	@$(PYTHON) -m build --wheel
.PHONY: system-up

run:
	@$(PYTHON) ./run.py
.PHONY: system-up
