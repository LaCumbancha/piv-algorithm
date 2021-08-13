SHELL := /bin/bash
PWD := $(shell pwd)
PYTHON := /usr/local/bin/python3 -W ignore

system-up:
	@$(PYTHON) ./run.py
.PHONY: system-up

build:
	@$(PYTHON) -m pip install build
	@$(PYTHON) -m build --wheel
.PHONY: system-up
