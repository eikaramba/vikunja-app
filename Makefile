GIT_LAST_COMMIT := $(shell git describe --tags --always | sed 's/-/+/' | sed 's/^v//')
FLUTTER ?= flutter

ifneq ($(DRONE_TAG),)
	VERSION ?= $(subst v,,$(DRONE_TAG))-$(GIT_LAST_COMMIT)
else
	ifneq ($(DRONE_BRANCH),)
		VERSION ?= $(subst release/v,,$(DRONE_BRANCH))-$(GIT_LAST_COMMIT)
	else
		VERSION ?= master-$(GIT_LAST_COMMIT)
	endif
endif

.PHONY: test
test:
	$(FLUTTER) test

.PHONY: build-all
build-all: build-release build-debug build-profile

.PHONY: build-release
build-release:
	$(FLUTTER) build apk --release --build-name=$(VERSION) --flavor main

.PHONY: build-debug
build-debug:
	$(FLUTTER) build apk --debug --build-name=$(VERSION) --flavor unsigned

.PHONY: build-profile
build-profile:
	$(FLUTTER) build apk --profile --build-name=$(VERSION) --flavor unsigned

.PHONY: format
format:
	$(FLUTTER) format lib

.PHONY: format-check
format-check:
	@diff=$$(flutter format -n lib); \
	if [ -n "$$diff" ]; then \
		echo "The following files are not formatted correctly:"; \
		echo "$${diff}"; \
		echo "Please run 'make format' and commit the result."; \
		exit 1; \
	fi;