const MAX_WIDTH = 960;
const MAX_HEIGHT = 1024;
const PREFER_CANVAS_CTX = "webgl";
let IS_DEV = undefined;
//IS_DEV = true;   // Uncomment to explicitly enable dev mode
//IS_DEV = false;  // Uncomment to explicitly disable dev mode
// otherwise dev mode will only be enabled if the hostname is localhost
// or 127.0.0.1.
const DEV_EVENT_SET_DRAWN_TIMESTAMP = 0;
const DEV_EVENT_SET_CANVAS_CTX = 1;

const body = document.getElementsByTagName("body")[0];
let canvas = document.getElementById("canvas");

let wasmInstance,
    drawFunction,
    updateGamePromise;
let devUpdate = () => {};

function main() {
    setupDevModeIfDev();

    drawFunction = setupCanvasForDrawing(PREFER_CANVAS_CTX);

    resize();

    let t0 = t1 = performance.now();
    function gameLoop() {
        updateGamePromise = Promise.all([
            // We run these operation asynchrously in case one of them
            // execute non-blocking code e.g. GPU operations.
            // This also gives us the option to run webassembly in a
            // web-worker in future.
            new Promise((resolve, reject) => {
                wasmInstance.exports.update(performance.now());
                resolve();
            }),
            new Promise((resolve, reject) => {
                drawFunction();
                devUpdate(DEV_EVENT_SET_DRAWN_TIMESTAMP, performance.now());
                resolve();
            }),
        ]);

        updateGamePromise.then(() => {
            requestAnimationFrame(gameLoop);
        });
    }

    const keyToCode = {
        "ArrowUp"   : wasmInstance.exports.ARROW_UP   ,
        "ArrowLeft" : wasmInstance.exports.ARROW_LEFT ,
        "ArrowDown" : wasmInstance.exports.ARROW_DOWN ,
        "ArrowRight": wasmInstance.exports.ARROW_RIGHT,
    };
    window.addEventListener(
        "keydown", 
        (e) => wasmInstance.exports.handleKeyDown(
                keyToCode[e.key] || e.keyCode),
    );
    window.addEventListener("resize", resize);

    requestAnimationFrame(gameLoop);
}

function resize() {
    canvas.width = Math.min(body.clientWidth, MAX_WIDTH);
    canvas.height = Math.min(body.clientHeight, MAX_HEIGHT);
    wasmInstance.exports.resize(canvas.width, canvas.height);
    wasmInstance.exports.update(performance.now());
}

function setupCanvasForDrawing(canvasCtxType) {
    let draw = function () {};

    switch (canvasCtxType) {
    case "webgl2":
    case "webgl":
        const gl = canvas.getContext(canvasCtxType, {
            alpha: true,
            depth: false,
            stencil: false,
            desynchronized: true,
            antialias: false,
            preserveDrawingBuffer: true,
        });

        // NOTE: This code is really slow and overcomplicated in comparison
        //       to the c implementation `src/platform_native__main.c`
        //       because WebGl does not support a glDrawPixels() equivalent
        //       because "ohh scary, manual memory addressing" which sucks.

        if (!gl) {
            if (canvasCtxType === "webgl2") {
                console.warn(
                    "WebGL 2 is not supported! " +
                    "Attempting to falling back on WebGL 1..."
                );

                return setupCanvasForDrawing("webgl");
            } else {
                console.warn(
                    "WebGL 1 is not supported! " +
                    "Attempting to falling back on canvas' 2d context..."
                );

                return setupCanvasForDrawing("2d");
            }
        }

        // Create the WebGL program with a vertex and fragment shader
        const glProgram = gl.createProgram();
        gl.attachShader(glProgram, createWebGlShader(gl, gl.VERTEX_SHADER, [
            "attribute vec2 vertCoord;",
            "varying vec2 texCoord;",
            "void main() {",
                // Let WebGL know where the vertex is
            "    gl_Position = vec4(vertCoord, 0, 1);",
                // Calculate the texture coordinate that will be used in the
                // fragments shader.
            "    texCoord = (vertCoord"
                + " + 1.0)"  // Center texture
                + " * 0.5;", // Scale texture x2
            "}",
        ].join("\n")));
        gl.attachShader(glProgram, createWebGlShader(gl, gl.FRAGMENT_SHADER, [
            // Set floating-point percision for shader to medium.
            "precision mediump float;",
            "uniform sampler2D tex;",
            // The texture coordinate, passed in from the vertex shader.
            "varying vec2 texCoord;",
            "void main() {",
            "    gl_FragColor = texture2D(tex, texCoord);",
            "}",
        ].join("\n")));
        gl.linkProgram(glProgram);
        if (!gl.getProgramParameter(glProgram, gl.LINK_STATUS)) {
            throw new Error(
                "Failed to link WegGL program: " +
                gl.getProgramInfoLog(glProgram)
            );
        }
        gl.useProgram(glProgram);

        // Draw a rectangle from 2 triangles
        const vertCoordAttributeLocation = gl.getAttribLocation(glProgram, "vertCoord");
        const vertCoordBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, vertCoordBuffer);
        const vertCoords = [
            // Triangle, diagnonally covering top-left half of screen
             1,  1,
            -1,  1,
            -1, -1,
            // Triangle, diagnonally covering bottom-right half of screen
            -1, -1,
             1, -1,
             1,  1,
        ];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertCoords), gl.STATIC_DRAW);
        gl.enableVertexAttribArray(vertCoordAttributeLocation);
        gl.vertexAttribPointer(
            vertCoordAttributeLocation,
            2,         // 2 because of the PAIRS of xs and ys in vertCoords
            gl.FLOAT,  // Vertex shader accepts vec2 of floats
            false,     // Don't normalize
            0,         // No stride in vertCoords
            0,         // No offset in vertCoords
        )

        // Create a texture to draw the pixels from wasm on.
        const pixelsTexture = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, pixelsTexture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);

        let rgbaArray;

        draw = function drawWebGl() {
            rgbaArray = new Uint8Array(
                wasmInstance.exports.memory.buffer,
                wasmInstance.exports.memoryRegionCanvasBytesOffset,
                wasmInstance.exports.memoryRegionCanvasBytesN,
            );
            gl.viewport(0, 0, canvas.width, canvas.height);
            gl.texImage2D(
                gl.TEXTURE_2D,
                0,
                gl.RGBA,
                canvas.width, canvas.height,
                0,
                gl.RGBA,
                gl.UNSIGNED_BYTE,
                rgbaArray,
            );

            gl.drawArrays(gl.TRIANGLES, 0, vertCoords.length/2);
        }

        break;
    case "2d":
        // Flip y-axis because we default to Web/OpenGl's y-axis' orientation
        canvas.style.transform = "scaleY(-1)";

        const ctx = canvas.getContext(canvasCtxType, {
            alpha: false,
            desynchronized: true,
            willReadFrequently: false,
        });

        draw = function drawCanvas2d() {
            // We create an RGBA byte array from the wasm memory region that we
            // reserved for the canvas RGBA data in the wat implementation 
            // and fill the canvas with it.
            // (See https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Pixel_manipulation_with_canvas
            // for ImageData stuff.)
            //
            // This is unreasonably slow and takes more time than the Webassembly
            // code (in Firefox, where I'm developing) which means that we
            // need to add a huge amount of complexity with WebGL to make it
            // reasonably fast -- to draw pixels you must suffer!... Aren't
            // web standards great
            ctx.putImageData(
                new ImageData(new Uint8ClampedArray(
                    wasmInstance.exports.memory.buffer,
                    wasmInstance.exports.memoryRegionCanvasBytesOffset,
                    wasmInstance.exports.memoryRegionCanvasBytesN,
                ), canvas.width, canvas.height), 
                0, 0,
                0, 0,
                canvas.width, canvas.height,
            );
        }
        break;
    default:
        console.error(`Unsupported canvas context: '${canvasCtxType}'`);
        return () => {};
    }

    console.info(`Using '${canvasCtxType}' canvas context.`);

    devUpdate(DEV_EVENT_SET_CANVAS_CTX, canvasCtxType);

    return draw;
}

/** Changes the canvas context type.
  * Use for testing in your webbrowser's console. */
function changeCanvasCtx(ctxType) {
    console.info("Replacing current canvas with a new one!");

    const oldCanvas = canvas;

    canvas = document.createElement("canvas");
    canvas.id = "canvas";
    canvas.width = oldCanvas.width;
    canvas.height = oldCanvas.height;
    canvas.style.backgroundColor = "black";
    oldCanvas.replaceWith(canvas);

    drawFunction = setupCanvasForDrawing(ctxType);
}

function setupDevModeIfDev() {
    const infoMsgStart =
        "Displaying developer information in top-right of screen ";
    const infoMsgEnd = " Set IS_DEV=false to remove info."
    if (IS_DEV === true) {
        console.info(
            infoMsgStart +
            "because IS_DEV=true." +
            infoMsgEnd);
    } else if (IS_DEV === false) {
        return;
    } else if (["127.0.0.1", "localhost"]
            .includes(window.location.hostname)) {
        console.info(
            infoMsgStart +
            `because hostname=${window.location.hostname}.` +
            infoMsgEnd
        );
    } else {
        return;
    }

    const AVG_FPS_DEQUE_SIZE = 100;

    // UI
    // ----------------------------------------------------------------------

    const infoDiv = document.createElement("div");
    infoDiv.style.color = "#000";
    infoDiv.style.backgroundColor = "#FFF8";
    infoDiv.style.position = "absolute";
    infoDiv.style.top = "8px";
    infoDiv.style.right = "8px";
    infoDiv.style.fontFamily = "sans-serif";
    infoDiv.style.textAlign = "right";
    infoDiv.style.padding = "8px";

        // Canvas context type
        const canvasCtxDiv = document.createElement("div");
            const canvasCtxLabel = document.createElement("span");
            const canvasCtxValue = document.createElement("span");
            canvasCtxLabel.textContent = "Canvas ctx: ";
            canvasCtxValue.textContent = "unset";
        canvasCtxDiv.appendChild(canvasCtxLabel);
        canvasCtxDiv.appendChild(canvasCtxValue);

        // FPS counter
        const fpsDiv = document.createElement("div");
            const fpsLabel = document.createElement("span");
            const fpsValue = document.createElement("span");
            fpsLabel.textContent = "FPS: ";
            fpsValue.textContent = "0";
        fpsDiv.appendChild(fpsLabel);
        fpsDiv.appendChild(fpsValue);

        // Avg. FPS counter
        const avgFpsDiv = document.createElement("div");
            const avgFpsLabel = document.createElement("span");
            const avgFpsValue = document.createElement("span");
            avgFpsLabel.textContent = `Avg. FPS (last ${AVG_FPS_DEQUE_SIZE}): `;
            avgFpsValue.textContent = "0";
        avgFpsDiv.appendChild(avgFpsLabel);
        avgFpsDiv.appendChild(avgFpsValue);

    infoDiv.appendChild(canvasCtxDiv);
    infoDiv.appendChild(fpsDiv);
    infoDiv.appendChild(avgFpsDiv);

    document.body.appendChild(infoDiv);

    // UI Update Logic
    // ----------------------------------------------------------------------

    let lastDrawnTimestamp = performance.now();
    const avgFpsDeque = [];

    devUpdate = function devUpdate(eventType) {
        switch (eventType) {
            case DEV_EVENT_SET_DRAWN_TIMESTAMP:
                const drawnTimestamp = arguments[1];

                const fps = 1000/(drawnTimestamp - lastDrawnTimestamp);
                fpsValue.textContent = parseFloat(fps).toFixed(2);

                avgFpsDeque.push(fps);
                if (avgFpsDeque.length > AVG_FPS_DEQUE_SIZE) {
                    avgFpsDeque.shift();
                }
                let avgFps = 0;
                for (const queueFps of avgFpsDeque) {
                    avgFps += queueFps/avgFpsDeque.length;
                }

                avgFpsValue.textContent = parseFloat(avgFps).toFixed(2);

                lastDrawnTimestamp = drawnTimestamp;

                break;
            case DEV_EVENT_SET_CANVAS_CTX:
                canvasCtxValue.textContent = arguments[1];
                break;
        }
    }
}

const importedByWasm = {
    logFromNBytesOfMemory(nBytes) {
        const latin1Bytes = new Uint8Array(
            wasmInstance.exports.memory.buffer,
            wasmInstance.exports.memoryRegionLogBytesOffset, nBytes
        );
        const chars = [];
        for (let i = 0; i < nBytes; ++i) {
            chars.push(String.fromCharCode(latin1Bytes[i]));
        }
        console.log(chars.join(""));
    },
};

WebAssembly.instantiateStreaming(fetch("snake.wasm"), {
    imports: importedByWasm,
}).then((obj) => {
    wasmInstance = obj.instance;
    main();
});


// Utils
// ----------------------------------------------------------------------

function createWebGlShader(gl, type, source) {
    const shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
        let typeName;
        switch (type) {
            case gl.VERTEX_SHADER:
                typeName = " vertex";
                break;
            case gl.FRAGMENT_SHADER:
                typeName = " fragment";
                break;
            default:
                typeName = "";
        } 
        throw new Error(
            `Failed to compile WebGL${typeName} shader: ` +
            gl.getShaderInfoLog(shader)
        )
    }

    return shader;
}
