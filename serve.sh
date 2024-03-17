#!/bin/sh

set -eu

HOST="localhost"
PORT="8080"

project_dir="$( dirname "$0" )"
build_dir="$project_dir/snake-web"

# Fail if build directory does not exist
if [ ! -d "$build_dir" ]; then
    echo "Cannot server content of build directory \
because build directory '$build_dir' does not exist!" &>2
    exit 1
fi

echo "Serving contents of build directory '$build_dir' \
(using python http.server)..."
python3 -m http.server -d "$build_dir" -b "$HOST" $PORT

