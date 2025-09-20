#!/bin/bash
# Convenient script to run the Flutter app in debug mode
# Usage: ./run_app.sh
# Automatically loads MongoDB connection and Gemini API key from .env file if present

# Load .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Build dart-define arguments
DART_DEFINES=""

if [ -n "$MONGODB_CONNECTION_STRING" ]; then
    echo "✅ MongoDB connection found"
    DART_DEFINES="$DART_DEFINES --dart-define=MONGODB_CONNECTION_STRING=\"$MONGODB_CONNECTION_STRING\""
else
    echo "⚠️  No MongoDB connection (using local storage)"
fi

if [ -n "$GEMINI_API_KEY" ]; then
    echo "✅ Gemini API key found"
    DART_DEFINES="$DART_DEFINES --dart-define=GEMINI_API_KEY=\"$GEMINI_API_KEY\""
else
    echo "⚠️  No Gemini API key (AI features disabled)"
fi

echo "🚀 Starting Flutter app..."
if [ -n "$DART_DEFINES" ]; then
    flutter run --debug $DART_DEFINES
else
    flutter run --debug
fi