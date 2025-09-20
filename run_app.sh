#!/bin/bash
# Convenient script to run the Flutter app in debug mode
# Usage: ./run_app.sh
# Automatically loads MongoDB connection from .env file if present

# Load .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

if [ -n "$MONGODB_CONNECTION_STRING" ]; then
    echo "Running with MongoDB connection..."
    flutter run --debug --dart-define=MONGODB_CONNECTION_STRING="$MONGODB_CONNECTION_STRING"
else
    echo "Running with local storage (no MongoDB)..."
    flutter run --debug
fi