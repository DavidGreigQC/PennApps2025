#!/bin/bash
# Convenient script to run the Flutter app with optimized MongoDB credentials
flutter run --debug --dart-define=MONGODB_CONNECTION_STRING="mongodb+srv://davidgreig:9to5QEq5G2aL77gN@cluster0.mafofei.mongodb.net/menu_optimizer?retryWrites=true&w=majority&authMechanism=SCRAM-SHA-1&tls=true&connectTimeoutMS=5000&serverSelectionTimeoutMS=5000"