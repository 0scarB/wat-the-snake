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
