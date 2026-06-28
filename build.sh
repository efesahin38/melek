#!/bin/bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web support
flutter config --enable-web

# Install dependencies
flutter pub get

# Build the app
flutter build web --release

# Add redirect rule for Netlify to handle Flutter web routing
echo "/* /index.html 200" > build/web/_redirects
