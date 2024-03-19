#!/bin/sh

set -eu

project_dir="$( dirname "$0" )"
src_dir="$project_dir/src"
build_dir_web="$project_dir/snake-web"
c_dir="$project_dir/snake-c"
native_exe="$project_dir/snake-native.exe"

wabt_cmd() {
    local cmd_name="$1"
    shift
    local wabt_build_dir="$project_dir/wabt-build"
    local project_exe_file="$wabt_build_dir/$cmd_name"
    if [ -f "$project_exe_file" ]; then
        eval "$project_exe_file $@"
    else
        if command -v "$cmd_name" 1>/dev/null; then
            echo "[WARNING] Did not find the project-local executable \
'$project_exe_file'. This should be created by running './setup.sh'. \
Run './setup.sh' if you haven't already! Found '$( command -v "$cmd_name" )' \
command already installed... Attempting to use."
            eval "$cmd_name $@"
        else
            echo "[ERROR] Did not find the project-local executable \
'$project_exe_file'. This should be created by running './setup.sh'. \
Run './setup.sh' if you haven't already!" 1>&2
            exit 1
        fi
    fi
}

_wat2wasm() {
    wabt_cmd 'wat2wasm' $@
}

_wasm2c() {
    wabt_cmd 'wasm2c' $@
}


# Web
# ----------------------------------------------------------------------

# Remove build directory if it already exists
if [ -d "$build_dir_web" ]; then
    echo "[Web] Old web-app directory '$build_dir_web' already exists. \
Removing..."
    rm -rf "$build_dir_web"
    echo "[Web] Removed directory."
fi

# Create the build directory
echo "[Web] Creating web-app '$build_dir_web'..."
mkdir "$build_dir_web"
echo "[Web] Created directory."

# Copy static files to the build directory
echo "[Web] Copy web platform files from '$src_dir' to '$build_dir_web'..."
cp "$src_dir/platform_web__index.html" "$build_dir_web/index.html"
cp "$src_dir/platform_web__index.js" "$build_dir_web/index.js"
echo "[Web] Copied files."

# Compile .wat file to .wasm file
echo "[Web] Compiling '$src_dir/snake.wat' to '$build_dir_web/snake.wasm'..."
_wat2wasm "$src_dir/snake.wat" -o "$build_dir_web/snake.wasm" --enable-threads
echo "[Web] Compiled .wasm file."


# Native
# ----------------------------------------------------------------------

if [ -d "$c_dir" ]; then
    echo "[Native] Old generated c-files directory '$c_dir' already exists. \
Removing..."
    rm -rf "$c_dir"
    echo "[Native] Removed directory."
fi

echo "[Native] Creating c-files directory '$c_dir'..."
mkdir "$c_dir"
echo "[Native] Created directory."

echo "[Native] Copy native platform c-files from \
'$src_dir' to '$c_dir'..."
cp "$src_dir/platform_native__main.c" "$c_dir/main.c"
echo "[Native] Copied files."

echo "[Native] Transpiling WASM-file '$build_dir_web/snake.wasm' \
to c-files '$c_dir/snake.c' and '$c_dir/snake.h'"
_wasm2c --enable-exceptions "$build_dir_web/snake.wasm" -o "$c_dir/snake.c"
echo "[Native] Transpiled WASM-file."

echo "[Native] Building executable with GLFW and OpenGl from c-files..."
compile_cmd="cc \
-ggdb \
$(pkg-config --with-path="$project_dir" --cflags glfw3 gl) \
-I$project_dir/wabt/wasm2c \
-I$c_dir \
-o $native_exe \
$c_dir/main.c $c_dir/snake.c \
$project_dir/wabt/wasm2c/wasm-rt-impl.c \
$(pkg-config --with-path="$project_dir" --static --libs glfw3 gl)"
#echo "$compile_cmd"
eval "$compile_cmd"
echo "[Native] Built native executable."

