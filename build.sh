#!/bin/sh

set -eu

project_dir="$( dirname "$0" )"
src_dir="$project_dir/src"
build_dir_web="$project_dir/snake-web"
native_exe="$project_dir/snake-native.exe"


_wat2wasm() {
    local wabt_build_dir="$project_dir/wabt-build"
    local local_wat2wasm_file="$wabt_build_dir/wat2wasm"
    if [ -f "$local_wat2wasm_file" ]; then
        eval "$local_wat2wasm_file $@"
    else
        if command -v 'wat2wasm' 1>/dev/null; then
            echo "[WARNING] Did not find the local executable \
'$local_wat2wasm_file'. This should be created by running './setup.sh'. \
Run './setup.sh' if you haven't already! Found '$( command -v 'wat2wasm' )' \
command already installed... Attempting to use."
            wat2wasm $@
        else
            echo "[ERROR] Did not find the local executable \
'$local_wat2wasm_file'. This should be created by running './setup.sh'. \
Run './setup.sh' if you haven't already!" 1>&2
            exit 1
        fi
    fi
}


# Web
# ----------------------------------------------------------------------

# Remove build directory if it already exists
if [ -d "$build_dir_web" ]; then
    echo "[Web] Old build directory '$build_dir_web' already exists. Removing..."
    rm -rf "$build_dir_web"
    echo "[Web] Removed directory."
fi

# Create the build directory
echo "[Web] Creating the build directory '$build_dir_web'..."
mkdir "$build_dir_web"
echo "[Web] Created directory."

# Copy static files to the build directory
echo "[Web] Copying static files from the source directory \
'$src_dir' to the build directory '$build_dir_web'..."
cp "$src_dir/index.html" "$build_dir_web/index.html"
cp "$src_dir/index.js" "$build_dir_web/index.js"
echo "[Web] Copied static files."

# Compile .wat file to .wasm file
echo "[Web] Compiling '$src_dir/snake.wat' to '$build_dir_web/snake.wasm'..."
_wat2wasm "$src_dir/snake.wat" -o "$build_dir_web/snake.wasm" --enable-threads
echo "[Web] Compiled .wasm file."


# Native
# ----------------------------------------------------------------------

echo "[Native] Building executable with GLFW and OpenGl..."
cc \
    $(pkg-config --with-path="$( pwd )" --cflags glfw3 gl) \
    -o "$native_exe" src/snake.c \
    $(pkg-config --with-path="$( pwd )" --static --libs glfw3 gl)
echo "[Native] Built native executable."

