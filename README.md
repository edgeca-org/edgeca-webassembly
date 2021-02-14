# EdgeCA
## Building a WebAssembly

It's possible to compile Go projects into [WebAssembly](https://webassembly.org/), which is a binary instruction format for a stack-based WebAssembly virtual machine. It's a portable target which is gaining popularity for implementing web applications in particular.

The WebAssembly can then be executed either by a JavaScript runtime environment like Node.js, or by a WebAssembly Runtime such as [Wasmer](https://wasmer.io/)
 
The universal binaries generated can work across operating systems (Linux, MacOS, Windows etc) and the runtime engine sandboxes them for secure execution. 

Support for Go is in more limited than support for languages such as Rust. WebAssemblies are usually treated like a library of functions. However, Go takes the different approach of building an application, where the webassembly glue code starts a Go runtime, it runs and exits. Therefore, some Go-specific JavaScript glue code is required.

The Go SDK contains some built-in scripts to run WebAssemblies using Node.js. To try this out, do the following:

```
./edgeca-wasm.sh gencsr --cn localhost --csr csr.pem --key csr-key.pem


Building WASM
running WASM
2021/02/07 23:22:26 Generated CSR for [ CN=localhost ]

```

This script compiles the EdgeCA application into a WASM file and runs it, passing the arguments given. You can therefore use this command in the same way as the edgeca command. 

The [edgeca-wasm.sh](edgeca-wasm.sh) script simply does the following:

```
#!/usr/bin/env bash

echo "Building WASM"
GOOS=js GOARCH=wasm go build -o edgeca.wasm ../../cmd/edgeca/main.go

echo "running WASM"
$(go env GOROOT)/misc/wasm/go_js_wasm_exec edgeca.wasm --wasm "$@"
```

The go_js_wasm_exec script uses Node.js to run the WebAssembly

However - the client is currently not able to connect to the server - and can therefore only generate CSRs, but not connect to the server to generate certificates. This is because WebAssembly code runs in a sandbox and has no access to TCP/IP sockets. The client communicates with the server using gRPC and therefore needs socket access for that.

A possible workaround would be to to use gRPC over websockets instead. That might be possible, using some of the available libraries, such as this [Minimal WebSocket library for Go](https://github.com/nhooyr/websocket), but that requires a number of other updates as well to work with the go_js_wasm_exec script.


