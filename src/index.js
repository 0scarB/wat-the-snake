const canvas = document.getElementById("canvas");
const ctx = canvas.getContext("2d");

// Set when the WebAssembly.instantiateStreaming resolves.
// See bottom of file
let wasmInstance;

function main() {
    setInterval(() => {
        if (wasmInstance.exports.shouldUpdate() === 1) {
            wasmInstance.exports.update();

            // We create an RGBA byte array from the wasm memory region that we
            // reserved for the canvas RGBA data in the wat implementation 
            // and fill the canvas with it.
            // (See https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Pixel_manipulation_with_canvas
            // for ImageData stuff.)
            const rgbaArray = new Uint8ClampedArray(
                wasmInstance.exports.memory.buffer,
                wasmInstance.exports.memoryRegionCanvasBytesOffset,
                wasmInstance.exports.memoryRegionCanvasBytesN,
            );
            const imageData = new ImageData(rgbaArray, canvas.width, canvas.height);
            ctx.putImageData(imageData, 0, 0);
        }
    }, 10)

    document.addEventListener(
        "keydown", 
        (e) => wasmInstance.exports.handleKeyDown(e.key.charCodeAt(0)),
    );
}

const importedByWasm = {
    canvasWidth : canvas.width,
    canvasHeight: canvas.height,

    logFromNBytesOfMemory(nBytes) {
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

    getUnixTimestamp() {
        return Date.now();
    },
};

WebAssembly.instantiateStreaming(fetch("snake.wasm"), {
    imports: importedByWasm,
}).then((obj) => {
    wasmInstance = obj.instance;
    main();
});

