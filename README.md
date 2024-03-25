# WAT the Snake

A cros-platform snake game written in the WebAssembly text format (WAT).

**Play the web version here <https://0scarb.github.io/wat-the-snake/>.**


# Downloading Native (PC / Laptop) Application

Currently the native version of the application can only run on Linux
and Windows with x86 CPUs (all PCs and most laptops, except those with
ARM CPUs -- Chrome Books, suface Laptops, etc.).

You can download the native executables by clicking "download native
executables" at the bottom right of the
website <https://0scarb.github.io/wat-the-snake/> and then clicking
on the Linux or Windows options respectively. The linux version
will be downloaded as a .tar archive which you can extract in your
downloads folder.

Alternatively, you can also downloads the relevant source file --
[`snake-x86-64-linux`](./snake-x86-64-linux) or
[`snake-x86-64-win.exe`](./snake-x86-64-linux) -- directly from this
git repository.


# Downloading the Static .html File

You can download [`snake-web.html`](./snake-web.html) and open it in
your browser as a static file. No internet connection required!

(The download links won't work because the link to seperate files.)


# Acknowledgements / Attribution

The software would not be possible without the awesome 3rd-party tools
and assets that it depends on and uses:

-   [WebAssembly](https://webassembly.org/) for truely cross-platform
    code and the
    [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt)
    as tooling
-   [GLFW](https://www.glfw.org/) for creating native PC / Laptop
    applications

    > Copyright (c) 2002-2006 Marcus Geelnard<br>
    > Copyright (c) 2006-2019 Camilla Löwy

    See contributers here:
        <https://github.com/glfw/glfw/blob/master/CONTRIBUTORS.md>.
    It provides sensible, well-made window creation, input handling
    and wrapping of OpenGL for visuals!
-   Awesome [Font Awesome](https://fontawesome.com/) icons to provide
    some visual finesse to the GitHub Pages website.


# Devlopment and Building from Source

The following steps assume you're working in a linux terminal. Submit
an issue if you want to hack on the project in a different developer
environment.

## Setup

Before getting started, your linux environment should have following
external dependencies set up:
-   The commands [`cmake`](https://cmake.org/),
    [`pkg-config`](https://www.freedesktop.org/wiki/Software/pkg-config/)
    should be on your `$PATH`
-   Fairly recent OpenGl headers should be discoverable by `pkg-config`
    -- if you don't know what this means, don't worry about it, it'll
    probably work out of the box.
-   You should install MinGW-w64 <https://www.mingw-w64.org/> and its
    `x86_64-w64-mingw32-gcc` command should be on your `$PATH`
-   Probably some other stuff that I'm forgetting

1.  Clone the repo `git clone git@github.com:0scarB/wat-the-snake.git`
    and cd to it.
2.  Run the `./setup.sh` shell script. This will
    a) download and compile the
    [WebAssembly Binary Toolkit](https://github.com/WebAssembly/wabt)
    and
    b) dowload and compile [GLFW](https://www.glfw.org/)

## Building

After the setup you can run the build script `./build.sh`.
This will:
1.  Compile the WebAssembly text file [`src/snake.wat`](./src/snake.wat)
    to the WebAssembly binary [`snake.wasm`](./snake.wasm) using
    the `wat2wasm` from the WebAssembly Binary Toolkit.
2.  (Re-)Generated [`snake-web.html`](./snake-web.html) from
    [`src/web.html`](./src/web.html), embedding the `snake.wasm`
    binary as a base64-encoded string in the HTML file.
3.  Generate C code in [`snake-c/`](./snake-c/) from the `snake.wasm`
    file and copy [`src/native.c`](./src/native.c) to
    [`snake-c/main.c`](./snake-c/main.c)
4.  Build the native Linux and Windows applications from the
    C code in `snake-c/`, linking with GLFW and OpenGl.
5.  Copy `snake-web.html` to (`docs/index.html`)[./docs/index.html]
    and tar and copy the executables for download to the `docs/`
    directory. The contents of the `docs/` directory are served
    on the GitHub Pages website <https://0scarb.github.io/wat-the-snake/>.


# Motivation / Discussion / Disparate Thoughts

I started this project because I wanted to learn a bit about WebAssembly
and ended up also learning a bit about creating cross-platform applications,
without the bloat and inefficiencies of stuff like Electron.

Working in the WebAssembly Binary Text Format (.wat) improved my intuition
regarding manual memory management. Among other things it forced me
to use a circular buffer to store the snake data. It turns out to be easier
to implement and much more efficient than a linked listed --
contiguous in memory, better cache coherence. I'll be on the lookout
for future use cases (you still need a linked listed when operating on data
that is in the middle though)!

Working in .wat isn't very practial and is better suited as a compile
target, once understood. Working in lower-level, simpler programming
languages does highlight what you miss and is actually necessary in
higher-level languages though.

Because I wanted to keep most of the logic in .wat file, the pixel data is
stored in WebAssembly's linear memory, meaning that I had to custom-implement
circle rendering, rasterization and even font rendering. This is
of course much less efficient that utilizing hardware acceleration the GPU
via OpenGL/WebGL. Looking at the results of profiling, the major bottle-neck
is actually copying the pixel data into GPUs VRAM (you need to use OpenGL
/ WebGL to actually display the pixels)
which is done every frame. This could be improved be keeping track of the
bounding boxes of only the pixels that changed from one frame to the next,
requiring only those regions to be copied,
but I couldn't be bothered to implement it because the project already
took longer to finish than I expected. To sum up, there's a lot of
performance being left on the table and I wouldn't copy this approach for
professional work. Despite that, I'm easily able to reach 60FPS and my
laptop.


# License

This project is licensed under the The Open Software License 3.0 license
with the intention of allowing others redistribute this code,
to modify derivate software and reuse sections of the code for other open
source projects, under the conditions that the derivate source code
stays open and that attribution is provided under the terms of the license.

All non-code, non-3rd-party assets and materials, **that do not fall under
the OSL-3.0**, contained in the git repository, are licensed under the
Creative Commons Attribution-ShareAlike 4.0 International license
CC BY-SA 4.0 license.

I'm open to discussing sublicensing if the OSL-3.0 does not meet your
needs. This is permissible as stated in paragraph 4 of the license,
"Nothing in this License shall be interpreted to prohibit Licensor from
licensing under terms different from this License".

