all: help

build:
	swift build -Xswiftc -static-stdlib -c release
	cp .build/release/radon bin/
	chmod +x bin/radon

help:
	@echo "Available make commands:"
	@echo "   $$ make help - display this message"
	@echo "   $$ make build - creates a new build"
