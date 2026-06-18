#!/bin/sh

wasm-opt \
	--dce \
	--rse \
	--signature-pruning \
	--strip-debug \
	--strip-producers \
	--disable-bulk-memory \
	-Oz target/wasm32-unknown-unknown/release/ninelives.wasm \
	-o $1.wasm-opt

wasm2wat "$1.wasm-opt" > "$1.wat"

wat2wasm "$1.wat" -o "$1"

rm "$1.wat" "$1.wasm-opt"
