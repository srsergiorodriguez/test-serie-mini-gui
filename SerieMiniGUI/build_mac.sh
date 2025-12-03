#!/bin/bash

# Configuration
APP_NAME="Serie Mini GUI"
APP_VERSION="1.0.0"
BUNDLE_ID="com.srsergior.serieminigui"
BUILD_DIR="Build_Mac"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"

# 1. Clean and Create Directories
echo "🧹 Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Resources"
mkdir -p "$CONTENTS_DIR/Frameworks"

echo "📂 Creating App Bundle Structure..."

# 2. Copy the Executable (LuaJIT)
# We copy it to MacOS/ and rename it to 'luajit-bin' to distinguish it from the launcher script
cp "LuaJIT/luajit-mac" "$CONTENTS_DIR/MacOS/luajit-bin"
chmod +x "$CONTENTS_DIR/MacOS/luajit-bin"

# 3. Copy Shared Libraries (.dylib) from your root Frameworks folder
echo "📦 Moving dynamic libraries from Root/Frameworks..."
cp Frameworks/*.dylib "$CONTENTS_DIR/Frameworks/"

# 4. Copy Resources (Lua files and Assets)
echo "📝 Copying Lua scripts and assets..."

# Copy main.lua and other root lua files
cp *.lua "$CONTENTS_DIR/Resources/"

# Copy assets folder
cp -r assets "$CONTENTS_DIR/Resources/"

# Copy lib folder (for the lua init files and bindings)
# We copy the whole thing, then scrub the binaries out in the next step
cp -r scripts "$CONTENTS_DIR/Resources/"

find "$APP_DIR" -name ".DS_Store" -delete

# 5. Create the Launcher Script
# This script runs when the user clicks the App Icon. 
# It sets up the path variables so LuaJIT finds the libraries in Frameworks.
LAUNCHER="$CONTENTS_DIR/MacOS/$APP_NAME"
cat > "$LAUNCHER" <<EOF
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
RESOURCE_PATH="\$DIR/../Resources"
FRAMEWORKS_PATH="\$DIR/../Frameworks"

# CRITICAL FIX: Change working directory to Resources
# This ensures require("lib...") and io.open("assets/...") work correctly.
cd "\$RESOURCE_PATH" || exit 1

# Add Frameworks to library search path so ffi.load("SDL3") works by name
export DYLD_LIBRARY_PATH="\$FRAMEWORKS_PATH:\$DYLD_LIBRARY_PATH"

# Run LuaJIT with main.lua
# We use 'exec' so the shell process is replaced by luajit
exec "\$DIR/luajit-bin" "main.lua"
EOF

chmod +x "$LAUNCHER"

# 6. Create Info.plist
# This tells macOS how to treat the folder as an Application
echo "📝 Generating Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 7. Ad-hoc Signing
echo "🔏 Signing libraries and executable..."
# Sign the frameworks first
codesign --force --deep -s - "$CONTENTS_DIR/Frameworks/"*.dylib
# Sign the binary
codesign --force -s - "$CONTENTS_DIR/MacOS/luajit-bin"
# Sign the launcher
codesign --force -s - "$CONTENTS_DIR/MacOS/$APP_NAME"
# Sign the whole bundle
codesign --force --deep -s - "$APP_DIR"

echo "✅ Success! App Bundle created at: $APP_DIR"
echo "👉 You can right-click '$APP_NAME.app' and choose 'Show Package Contents' to verify structure."