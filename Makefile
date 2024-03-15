.PHONY: build
all: build

build:
	docker rm -f circuitpython
	docker build -t circuitpython .
	docker run --name circuitpython circuitpython
	docker cp circuitpython:/firmware/circuitpython-firmware.bin .
	docker rm circuitpython
