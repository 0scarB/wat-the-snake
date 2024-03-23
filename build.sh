#!/bin/sh

set -eu

project_dir="$( dirname "$0" )"
src_dir="$project_dir/src"
c_dir="$project_dir/snake-c"
wasm_file="$project_dir/snake.wasm"
native_exe="$project_dir/snake-native.exe"
html_file="$project_dir/snake-web.html"

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

# Compile .wat file to .wasm file
echo "Compiling .wasm file from .wat: '$src_dir/snake.wat' -> '$wasm_file'..."
_wat2wasm "$src_dir/snake.wat" -o "$wasm_file" --enable-threads
echo "Compiled .wasm file."


# Web
# ----------------------------------------------------------------------

echo "[Web] Embedding WASM binary as base64 encoding string in \
.html and copying .html: $src_dir/web.html -> $html_file..."
wasm_binary_base64="$( base64 --wrap=0 "$wasm_file" )"
wasm_binary_base64_slashes_escaped="$( echo "$wasm_binary_base64" | sed 's/\//\\\//g' )"
sed "s/\\/\\*embed_wasm_base64\\*\\//\"${wasm_binary_base64_slashes_escaped}\"/g" \
    "$src_dir/web.html" > "$html_file"
echo "[Web] Embeded WASM binary and copied .html."


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

echo "[Native] Copy native c source file from '$src_dir/native.c' to '$c_dir'..."
cp "$src_dir/native.c" "$c_dir/main.c"
echo "[Native] Copied files."

echo "[Native] Transpiling WASM-file "$wasm_file" \
to c-files '$c_dir/snake.c' and '$c_dir/snake.h'"
_wasm2c --enable-exceptions './snake.wasm' -o "$c_dir/snake.c"
echo "[Native] Transpiled WASM-file."

echo "[Native] Building executable with GLFW and OpenGl from c-files..."
compile_cmd="cc \
-O3 \
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

