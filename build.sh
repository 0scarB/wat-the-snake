#!/bin/sh

set -eu

project_dir="$( dirname "$0" )"
src_dir="$project_dir/src"
build_dir_web="$project_dir/snake-web"
native_exe="$project_dir/snake-native.exe"


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
wat2wasm "$src_dir/snake.wat" -o "$build_dir_web/snake.wasm" --enable-threads
echo "[Web] Compiled .wasm file."


# Native
# ----------------------------------------------------------------------

echo "[Native] Building executable with GLFW and OpenGl..."
cc \
    $(pkg-config --with-path="$( pwd )" --cflags glfw3 gl) \
    -o "$native_exe" src/snake.c \
    $(pkg-config --with-path="$( pwd )" --static --libs glfw3 gl)
echo "[Native] Built native executable."

