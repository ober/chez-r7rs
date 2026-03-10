SCHEME     = scheme
LIBDIR     = lib
TEST_DIR   = tests

.PHONY: test test-base test-char test-lazy test-write test-records \
        test-division test-ports test-define-library clean help

## Default target: run all tests
test:
	$(SCHEME) --libdirs $(LIBDIR) --program $(TEST_DIR)/run-all.ss

## Run individual test files
test-base:
	$(SCHEME) --libdirs $(LIBDIR) --eval \
		'(import (scheme base)) (load "$(TEST_DIR)/base-test.ss")'

test-char:
	$(SCHEME) --libdirs $(LIBDIR) --eval \
		'(library-directories (list "$(LIBDIR)")) (load "$(TEST_DIR)/char-test.ss")'

test-lazy:
	$(SCHEME) --libdirs $(LIBDIR) --eval \
		'(library-directories (list "$(LIBDIR)")) (load "$(TEST_DIR)/lazy-test.ss")'

## Check that all library files are syntactically loadable
check-syntax:
	@for f in $$(find $(LIBDIR) -name '*.sls'); do \
		echo "Checking $$f ..."; \
		$(SCHEME) --libdirs $(LIBDIR) --eval \
			"(guard (e (#t (display \"ERROR in $$f: \") (display (condition/message e)) (newline) (exit 1))) (load \"$$f\"))" \
			|| exit 1; \
	done
	@echo "All files OK"

## Pre-compile libraries to .so for faster loading
compile:
	$(SCHEME) --libdirs $(LIBDIR) --compile-imported-libraries --eval \
		'(for-each (lambda (lib) \
			(guard (e (#t (void))) (import lib))) \
			(quote ((scheme base) (scheme char) (scheme complex) \
				(scheme case-lambda) (scheme cxr) (scheme eval) \
				(scheme file) (scheme inexact) (scheme lazy) \
				(scheme load) (scheme process-context) (scheme r5rs) \
				(scheme read) (scheme repl) (scheme time) (scheme write))))'

## Install to a specified destination (e.g. make install PREFIX=/usr/local)
install:
	@if [ -z "$(DESTDIR)" ]; then \
		echo "Usage: make install DESTDIR=/path/to/chez/lib"; \
		exit 1; \
	fi
	cp -r $(LIBDIR)/scheme $(DESTDIR)/
	cp -r $(LIBDIR)/r7rs   $(DESTDIR)/
	@echo "Installed to $(DESTDIR)"

## Remove compiled artifacts
clean:
	find $(LIBDIR) -name "*.so" -delete
	find $(LIBDIR) -name "*.wpo" -delete
	@echo "Clean complete"

help:
	@echo "Targets:"
	@echo "  test             — Run full test suite"
	@echo "  compile          — Pre-compile libraries to .so"
	@echo "  install DESTDIR= — Install to a directory"
	@echo "  clean            — Remove compiled artifacts"
	@echo "  check-syntax     — Verify all .sls files load without error"
