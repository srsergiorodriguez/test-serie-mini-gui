#!/bin/bash

# Configuration
APP_NAME="Serie Mini GUI"
BUILD_DIR="Build_Linux"
APP_DIR="$BUILD_DIR/$APP_NAME"

# 1. Clean and Create Directories
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/bin"
mkdir -p "$APP_DIR/lib"

echo "📂 Creating Linux App Structure..."

# 2. Copy Executable
# We place the binary in a 'bin' subfolder and rename it
echo "🏃 Copying Executable..."
cp "LuaJIT/luajit-linux" "$APP_DIR/bin/luajit-bin"
cp "LuaJIT/libluajit-5.1.so" "$APP_DIR/bin/" # Tal vez no es necesario si pongo el so en lib
chmod +x "$APP_DIR/bin/luajit-bin"

# 3. Copy Shared Libraries (.so)
# We find all .so files in your source 'lib' folder and flatten them into 'libs'
# This separates system binaries from your Lua 'lib' folder
echo "📦 Moving shared libraries (.so) to lib/..."

# 4. Copy Resources (Lua files and Assets)
echo "📝 Copying Lua scripts and assets..."

# Copy root lua files
cp *.lua "$APP_DIR/"

# Copy lib folder with .so files
cp -r lib "$APP_DIR/"

# Copy assets folder
cp -r assets "$APP_DIR/"

# Copy scripts folder with lua scripts
cp -r scripts "$APP_DIR/"

# 5. Cleanup Non-Linux Binaries
# We remove Windows/Mac binaries from the resource lib folder
echo "🧼 Cleaning non-Linux binaries..."

find "$APP_DIR" -name "*.dll" -delete
find "$APP_DIR" -name "*.dylib" -delete
find "$APP_DIR" -name "*.exe" -delete
find "$APP_DIR" -name ".DS_Store" -delete

# 6. Create the Launcher Script
# This is crucial on Linux. It sets LD_LIBRARY_PATH so the app finds dependencies.
LAUNCHER="$APP_DIR/$APP_NAME.sh"
echo "🚀 Creating launcher script..."

cat > "$LAUNCHER" <<EOF
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"

# Set the library path to our 'libs' folder
export LD_LIBRARY_PATH="\$DIR/libs:\$LD_LIBRARY_PATH"

# Run LuaJIT from bin/ pointing to main.lua in root
exec "\$DIR/bin/luajit-bin" "\$DIR/main.lua"
EOF

chmod +x "$LAUNCHER"

echo ""
echo "✅ Success! Linux App created at: $APP_DIR"
echo "👉 To run it: $APP_DIR/$APP_NAME.sh"