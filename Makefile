CONFIGURATION := release

ensure.pre-commit:
	which pre-commit &> /dev/null || pip install pre-commit

install: ensure.pre-commit
	pre-commit install

format: ensure.pre-commit
	pre-commit run --all-files

build:
	swift build -c $(CONFIGURATION)
	cp .build/$(CONFIGURATION)/itest-scanner /usr/local/bin/

build.debug:
	make build CONFIGURATION=debug
