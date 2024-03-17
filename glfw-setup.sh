#!/bin/sh

echo "Intializing and updating glfw submodule..."
git submodule init glfw
git submodule update glfw
echo "Initialized and updated submodule."

echo "Building and compiling glfw..."
cmake -S ./glfw -B ./glfw-build
cmake --build ./glfw-build
echo "Built and compiled glfw."
