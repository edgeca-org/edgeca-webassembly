#!/usr/bin/env bash

echo "Building WASM"
GOOS=js GOARCH=wasm go build -o edgeca.wasm ../../cmd/edgeca/main.go

echo "running WASM"
$(go env GOROOT)/misc/wasm/go_js_wasm_exec edgeca.wasm "$@"
