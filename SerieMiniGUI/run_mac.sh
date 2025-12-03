#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# Prepend our local Frameworks/ so macOS loads these .dylibs first
export DYLD_LIBRARY_PATH="$DIR/Frameworks:$DYLD_LIBRARY_PATH"

# Launch the bundled LuaJIT interpreter
exec "$DIR/LuaJIT/luajit-mac" "$DIR/main.lua"