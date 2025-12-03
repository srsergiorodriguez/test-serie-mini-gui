#!/bin/bash

# Configuration
APP_NAME="Serie Mini GUI"
BUILD_DIR="Build_Win"
APP_DIR="$BUILD_DIR/$APP_NAME"

# 1. Clean and Create Directories
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"

echo "📂 Creating Windows App Structure..."

# 2. Copy Executable and Core DLL
# We rename luajit.exe to your App Name so users see "MyCreativeApp.exe"
echo "🏃 Copying Executable..."
cp "LuaJIT/luajit.exe" "$APP_DIR/$APP_NAME.exe"
cp "LuaJIT/lua51.dll" "$APP_DIR/"

# 3. Copy Shared Libraries (DLLs)
# We move these to the root folder. Windows searches for DLLs
# in the same directory as the executable.
echo "📦 Moving DLLs to root..."

# Check and copy each known DLL
# We use -f to check existence to avoid errors if a lib was removed
[ -f "SDL3.dll" ] && cp "SDL3.dll" "$APP_DIR/"
[ -f "SDL3_ttf.dll" ] && cp "SDL3_ttf.dll" "$APP_DIR/"
[ -f "SDL3_image.dll" ] && cp "SDL3_image.dll" "$APP_DIR/"
[ -f "SDL3_mixer.dll" ] && cp "SDL3_mixer.dll" "$APP_DIR/"
[ -f "cimgui.dll" ] && cp "cimgui.dll" "$APP_DIR/"
[ -f "libnfdex.dll" ] && cp "libnfdex.dll" "$APP_DIR/"

# 4. Copy Resources (Lua files and Assets)
echo "📝 Copying Lua scripts and assets..."

# Copy root lua files
cp *.lua "$APP_DIR/"

# Copy assets folder
cp -r assets "$APP_DIR/"

# Copy scripts folder (for the lua init files and bindings)
cp -r scripts "$APP_DIR/"

# 5. Cleanup Non-Windows Binaries
# We remove source binaries from the 'lib' subfolder because we moved the
# active ones to the root, and we definitely don't want Mac/Linux files here.
echo "🧼 Cleaning non-Windows binaries..."

# Delete all dylib (Mac) and so (Linux)
find "$APP_DIR" -name "*.dylib" -delete
find "$APP_DIR" -name "*.so" -delete
# Remove .DS_Store files if created on Mac
find "$APP_DIR" -name ".DS_Store" -delete

echo ""
echo "✅ Success! Windows App created at: $APP_DIR"
echo "👉 You can zip the folder '$APP_DIR' for distribution."