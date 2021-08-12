SHELL := /bin/bash
PWD := $(shell pwd)
PYTHON := /usr/local/bin/python3 -W ignore

system-up:
	@$(PYTHON) ./run.py
.PHONY: system-up
