#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="${PROJECT_DIR}/../Geny/backend"

echo "==> Building backend..."
cd "$BACKEND_DIR"
npm install
npm run build

echo "==> Building Flutter app..."
cd "$PROJECT_DIR"
flutter build macos

echo "==> Bundling backend into app..."
APP_BUNDLE="$PROJECT_DIR/build/macos/Build/Products/Release/geny_flutter.app"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources/backend"

mkdir -p "$RESOURCES_DIR"
cp -R "$BACKEND_DIR/dist" "$RESOURCES_DIR/dist"
cp -R "$BACKEND_DIR/node_modules" "$RESOURCES_DIR/node_modules"
cp "$BACKEND_DIR/package.json" "$RESOURCES_DIR/package.json"

# Copy agents if they exist
if [ -d "$BACKEND_DIR/agents" ]; then
  cp -R "$BACKEND_DIR/agents" "$RESOURCES_DIR/agents"
fi

echo "==> Build complete: $APP_BUNDLE"
