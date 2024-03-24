#!/bin/sh

set -eu

wabt_git_tag='1.0.34'

echo "[Snake] Intializing and updating git submodules..."
git submodule update --init --recursive wabt
git submodule update --init glfw
echo "[Snake]     Creating local branch 'v$wabt_git_tag' \
in 'wabt' submodule to point at the tag commit..."
cd wabt 
git checkout "$wabt_git_tag"
git switch -C "v$wabt_git_tag"
git checkout "v$wabt_git_tag"
cd ..
echo "[Snake]     Created branch."
git submodule update wabt
echo "[Snake] Initialized and updated submodules."

echo "[Snake] Building and compiling wabt..."
cmake -S ./wabt -B ./wabt-build
cmake --build ./wabt-build
echo "[Snake] Built and compiled wabt."

echo "[Snake] Building and compiling glfw..."
cmake -S ./glfw -B ./glfw-build
cmake --build ./glfw-build
echo "[Snake] Built and compiled glfw."

glfw_win64_remote_archive_name='glfw-3.4.bin.WIN64'
echo "[Snake] Downloading glfw pre-compiled binaries for use with mingw..."
wget "https://github.com/glfw/glfw/releases/download/3.4/$glfw_win64_remote_archive_name.zip" \
    -O ./glfw-win64.zip
echo "[Snake] Downloaded glfw mingw stuff."
if [ -d './glfw-win64' ]; then
    echo "[Snake] Old unzipped destination directory already exists. Removing..."
    rm -rf ./glfw-win64
    echo "[Snake] Removed old unzipped directory."
fi
echo "[Snake] Unzipping glfw pre-compiled binaries for use with mingw.."
unzip ./glfw-win64.zip -d .
mv "$glfw_win64_remote_archive_name" './glfw-win64'
echo "[Snake] Unzippped."
echo "[Snake] Removing zip archive..."
rm ./glfw-win64.zip
echo "[Snake] Removed zip archive."
