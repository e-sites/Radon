all: help

build:
	swift build --configuration release --arch arm64 --arch x86_64
	rm -rf bin/radon
	cp .build/Apple/Products/Release/radon bin/
	chmod +x bin/radon

help:
	@echo "Available make commands:"
	@echo "   $$ make help - display this message"
	@echo "   $$ make build - creates a new build"
