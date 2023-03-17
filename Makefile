.PHONY: all test build
PREFIX ?= /usr
LOCALE_LOCATION ?= /share/locale

all: build

build:
	shards build -Dpreview_mt --no-debug
	cp bin/teledream /home/pim/cSD/stable-diffusion/

build_release:
	shards build -Dpreview_mt --release --no-debug

test:
	crystal spec -Dpreview_mt --order random
