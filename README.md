# WAT the Snake

A snake game written in the WebAssembly text format (WAT).


## Usage

1. Make sure the `wat2wasm` executable from the
   [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt)
   and a recent version of the [`python3`](https://www.python.org/)
   executable can be run in your terminal.
   (`python3` is only required for `./serve.sh` -- see below.
   Feel free to use your preferred method to serve the contents
   of the `./build/` if that's easier.)
2. Run the `./build.sh` Unix shell script. This will generate the
   directory `./build/` which contain the files for a static website.
3. Serve the static website in `./build/` by running the `./serve.sh`
   script.


## Developer Resources

- surma.dev / Raw WebAssembly -- <https://surma.dev/things/raw-wasm/>
  > A good, concise introduction to the core concepts.
  > Dosen't cover control flow though.
- dkwr.de / Dive into Wasm: Control flow instructions --
  <https://blog.dkwr.de/development/wasm-control-flow/>
  > Great, quick intro to control flow in WAT
- WAT spec -- <https://webassembly.github.io/spec/core/text/index.html>
- MDN / WebAssembly -- <https://developer.mozilla.org/en-US/docs/WebAssembly>
  - Understanding WebAssembly text format --
    <https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format>


## Motivation

I want to learn a bit of WebAssembly because I'm planning to use it
as a compilation target in other projects.

