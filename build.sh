#!/bin/sh

set -eu

project_dir="$( dirname "$0" )"
src_dir="$project_dir/src"
build_dir="$project_dir/build"

# Remove build directory if it already exists
if [ -d "$project_dir/build" ]; then
    echo "Old build directory '$build_dir' already exists. Removing..."
    rm -rf "$build_dir"
    echo "Removed directory."
fi

# Create the build directory
echo "Creating the build directory '$build_dir'..."
mkdir "$build_dir"
echo "Created directory."

# Copy static files to the build directory
echo "Copying static files from the source directory \
'$src_dir' to the build directory '$build_dir'..."
cp "$src_dir/index.html" "$build_dir/index.html"
cp "$src_dir/index.js" "$build_dir/index.js"
echo "Copied static files."

# Compile .wat file to .wasm file
echo "Compiling '$src_dir/snake.wat' to '$build_dir/snake.wasm'..."
wat2wasm "$src_dir/snake.wat" -o "$build_dir/snake.wasm" --enable-threads
echo "Compiled .wasm file."

