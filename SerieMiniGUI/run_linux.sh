#!/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prepend our local lib/ so macOS loads these .so first
export LD_LIBRARY_PATH="$DIR/lib:$LD_LIBRARY_PATH"

# Launch the bundled LuaJIT interpreter
exec "$DIR/LuaJIT/luajit-linux" "$DIR/main.lua"