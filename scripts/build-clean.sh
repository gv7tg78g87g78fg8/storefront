#!/bin/bash
set -e

# Скрипт для сборки без npm warnings
# Использование: ./scripts/build-clean.sh [env-file]

ENV_FILE=${1:-.env.development}
echo "🏗️  Building with environment: $ENV_FILE"

# Detect available package manager with preference for pnpm (same logic as dev.sh)
# First try to enable pnpm via corepack if available
if command -v corepack > /dev/null 2>&1; then
    corepack enable 2>/dev/null || true
fi

# Check for pnpm first (preferred)
if command -v pnpm > /dev/null 2>&1 && pnpm --version > /dev/null 2>&1; then
    # Test if pnpm can execute dotenv (the actual command for dotenv-cli package)
    if pnpm exec dotenv --help > /dev/null 2>&1; then
        PKG_MANAGER="pnpm"
        PKG_EXEC="pnpm exec"
        DOTENV_CMD="dotenv"  # pnpm uses 'dotenv' command from dotenv-cli package
        echo "📦 Using package manager: $PKG_MANAGER (with pnpm configuration)"
    else
        echo "⚠️  pnpm found but dotenv not available, falling back to npm"
        PKG_MANAGER="npm"
        PKG_EXEC="npx"
        DOTENV_CMD="dotenv-cli"  # npm uses 'dotenv-cli' command
        echo "📦 Using package manager: $PKG_MANAGER (fallback from pnpm)"
    fi
elif command -v npm > /dev/null 2>&1 && npm --version > /dev/null 2>&1; then
    PKG_MANAGER="npm"
    PKG_EXEC="npx"
    DOTENV_CMD="dotenv-cli"  # npm uses 'dotenv-cli' command
    # Temporarily remove problematic npm settings
    export npm_config_verify_deps_before_run=false
    export npm_config__jsr_registry=
    echo "📦 Using package manager: $PKG_MANAGER (with npm configuration)"
else
    echo "❌ No package manager found. Please install npm or pnpm."
    exit 1
fi

# Determine which Svelte config to use based on environment
if [[ "$ENV_FILE" == *"production"* ]]; then
    echo "🎭 Using production build configuration"
    cp svelte.config.production.js svelte.config.js
elif [[ "$ENV_FILE" == *"test"* ]]; then
    echo "🧪 Using test build configuration" 
    cp svelte.config.test.js svelte.config.js
else
    echo "💻 Using development build configuration"
    cp svelte.config.local.js svelte.config.js
fi

# Run build with proper environment configuration
$PKG_EXEC $DOTENV_CMD -e "$ENV_FILE" -- $PKG_MANAGER run build

echo "✅ Build completed successfully!"
