ASSETS := $(shell yq e ".assets.[].src" manifest.yaml)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
VERSION := $(shell yq e ".version" manifest.yaml)
HAVEN_SRC := $(shell find ./monero -name '*.rs') monero/Cargo.toml monero/Cargo.lock

.DELETE_ON_ERROR:

all: monerod.s9pk

install: monerod.s9pk
	appmgr install monerod.s9pk

monerod.s9pk: manifest.yaml config_spec.yaml config_rules.yaml image.tar instructions.md $(ASSET_PATHS)
	appmgr -vv pack $(shell pwd) -o monerod.s9pk
	appmgr -vv verify monerod.s9pk

instructions.md: README.md
	cp README.md instructions.md

image.tar: Dockerfile docker_entrypoint.sh monero/target/armv7-unknown-linux-musleabihf/release/monerod manifest.yaml
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/monerod --platform=linux/arm/v7 -o type=docker,dest=image.tar .

monero/target/armv7-unknown-linux-musleabihf/release/monerod: $(HAVEN_SRC)
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/monero:/home/rust/src start9/rust-musl-cross:armv7-musleabihf cargo +beta build --release
	docker run --rm -it -v ~/.cargo/registry:/root/.cargo/registry -v "$(shell pwd)"/monero:/home/rust/src start9/rust-musl-cross:armv7-musleabihf musl-strip target/armv7-unknown-linux-musleabihf/release/monerod

