# EdgeCA WebAssembly support
## Summary

It's possible to compile EdgeCA into a WebAssembly, which can then be executed either server-side on NodeJS or in a browser. **However**,  a number of limitations with the official Go compiler in WebAssembly support for networking and encryption prevent it from being usable. 

We expect the Golang project to add the required support in the future an then this would be a viable option. For now it remains difficult to run EdgeCA as a WebAssembly.


## WebAssembly

It's possible to compile Go projects into [WebAssembly](https://webassembly.org/), which is a binary instruction format for a stack-based WebAssembly virtual machine. It's a portable target which is gaining popularity for implementing web applications in particular.

WebAssemblies can be executed either by a JavaScript runtime environment like Node.js, or by a WebAssembly Runtime such as [Wasmer](https://wasmer.io/). Wasmer does not support running Webassembly files compiled with the official Go compiler, as the WASI target is not yet supported by the Go compiler. 
 
The universal binaries generated can work across operating systems (Linux, MacOS, Windows etc) and the runtime engine sandboxes them for secure execution. 

WebAssemblies are usually written in Rust or C/C++. Go also supports compiling to a WebAssembly target. **However**, support for Golang webassemblies is in early stages and comes with a number of limitations and issues.

### What is currently possible?

Go only builds WebAssemblies for a JavaScript target. What that means is that to run a Go webassembly, some JavaScript glue code is required - the target is "js" rather whan "wasm". That is the reason the resulting file can't be run directly with Wasmer. Instead, The Go SDK contains some built-in scripts to run WebAssembly files using Node.js. 

To build an EdgeCA webassembly, do the following:


```
git clone git@github.com:edgeca-org/edgeca.git
cd edgeca
GOOS=js GOARCH=wasm go build -o edgeca.wasm ./cmd/edgeca/main.go
```

Then run the resulting WASM file with Node.js using the glue script provided, as follows:

```
cp $(go env GOROOT)/misc/wasm/wasm_exec.js .
node wasm_exec edgeca.wasm gencsr --cn localhost --csr csr.pem --key csr-key.pem
```

and that should generate a CSR.

### What is not possible?

**Using gRPC is not possible**, as arbitrary TCP/IP connections are currently not supported. The WASI initiative will add features required to be used outside the browser, like File I/O and networking primitives. However, that is not yet supported in Go 1.15. Therefore, if we try to sign a certificate, we get an error message:

```
~/work/webassembly/edgeca$ node wasm_exec edgeca.wasm gencert --csr csr.pem 
2021/02/14 16:13:38 Connecting to edgeca server at js to sign certificate
2021/02/14 16:13:38 Loading TLS certificates from /home/sidar/.edgeca/certs
2021/02/14 16:13:38 could not get: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing dial tcp: Protocol not available"
```

A possible workaround would be to to use gRPC over websockets instead, such as in this [Minimal WebSocket library for Go](https://github.com/nhooyr/websocket), but that requires a number of other updates as well to work with the go_js_wasm_exec script. Another workaround would therefore be to merge the EdgeCA CLI and server into one application.

Even so, there are still **issues with encryption and network support, which prevent EdgeCA from working as expected**. For instance, the Venafi VCert TPP code does not currently compile to a webassembly target, again because of TCP/IP socket issues - we get a:

```
panic: interface conversion: net.Addr is *net.UDPAddr, not *net.TCPAddr

goroutine 1 [running]:
net.socket(0xf53c0, 0x81a090, 0x97cc8, 0x3, 0x2, 0x2, 0x0, 0x0, 0xf6560, 0x0, ...)
	/usr/local/go/src/net/net_fake.go:90 +0x84
net.internetSocket(0xf53c0, 0x81a090, 0x97cc8, 0x3, 0xf6560, 0x0, 0xf6560, 0x824b10, 0x2, 0x0, ...)
	/usr/local/go/src/net/ipsock_posix.go:141 +0x3

```

We were able to compile an earlier version of vCert into a WebAssembly, but the current v4 version requires updates to compile.

## TinyGO WASI support

As a result of the  ongoing WASI issues (see [31105](https://github.com/golang/go/issues/31105) and [38248](https://github.com/golang/go/issues/38248) ) in the official compiler, the TinyGo compiler has tried to resolve them with its own implementation. It has [support for WASI](
https://tinygo.org/webassembly/webassembly/) and does therefore not come with limitations of needing JavaScript glue code. 

However, that is also in early experimental stages and it does specifically not support the encryption and networking packages required by EdgeCA, so we get errors like:

```
tinygo build -o edgeca.wasm -target=wasm ./cmd/edgeca/main.go 
# vendor/golang.org/x/crypto/cryptobyte
/usr/local/go/src/vendor/golang.org/x/crypto/cryptobyte/asn1.go:14:2: could not import golang.org/x/crypto/cryptobyte/asn1 (package not imported: golang.org/x/crypto/cryptobyte/asn1)

```

In theory, if that would compile, then all that would be needed to run the resulting wasm would be to do

```
wasmer edgega.wasm
```

## Conclusion

So this remains an interesting option but support for generating and running WASM files from Go is still in very early stages and is not production ready.
