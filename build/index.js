const canvas = document.getElementById("canvas");
const canvasWidth = canvas.width;
const canvasHeight = canvas.height;
const ctx = canvas.getContext("2d");

let wasmInstance;

function main() {
    wasmInstance.exports.main();
    fillCanvasFromWasmMemory();
}

function fillCanvasFromWasmMemory() {
    // Create an instance of ImageData from the first
    // canvasWidth*canvasHeight*4 bytes of 'canvasMemory' from wasm
    // and fill the canvas with it.
    // (See https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Pixel_manipulation_with_canvas
    // for ImageData stuff.)
    const rgbaArray = new Uint8ClampedArray(
        wasmInstance.exports.memory.buffer,
        wasmInstance.exports.memoryLogRegionBytesN, canvasWidth*canvasHeight*4
    );
    const imageData = new ImageData(rgbaArray, canvasWidth, canvasHeight);
    ctx.putImageData(imageData, 0, 0);
}

WebAssembly.instantiateStreaming(
    fetch("snake.wasm"),
    {
        imports: {
            canvasWidth,
            canvasHeight,
            logFromNBytesOfMemory: (nBytes) => {
                const latin1Bytes = new Uint8Array(
                    wasmInstance.exports.memory.buffer,
                    0, nBytes
                );
                const chars = [];
                for (let i = 0; i < nBytes; ++i) {
                    chars.push(String.fromCharCode(latin1Bytes[i]));
                }
                console.log(chars.join(""));
            },
        }
    },
).then((obj) => {
    wasmInstance = obj.instance;
    main();
});

