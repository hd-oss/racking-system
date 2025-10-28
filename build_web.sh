#!/bin/bash

# Build script untuk production
# Load environment variables dan build Flutter web untuk Vercel deployment

echo "=== Warehouse Racking - Build Production ==="
echo ""

# Load environment variables dari .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
  echo "✓ Environment variables loaded dari .env"
else
  echo "✗ Error: .env file not found"
  exit 1
fi

echo ""
echo "=== Building Flutter Web ==="
echo ""

# Build Flutter web dengan environment variables
flutter build web --release \
  --dart-define=PARSE_APP_ID=$PARSE_APP_ID \
  --dart-define=PARSE_SERVER_URL=$PARSE_SERVER_URL \
  --dart-define=PARSE_CLIENT_KEY=$PARSE_CLIENT_KEY

# Check if build successful
if [ $? -ne 0 ]; then
  echo ""
  echo "✗ Build failed!"
  exit 1
fi

echo ""
echo "✓ Build web berhasil!"
echo ""
echo "=== Copying to public/ for Vercel deployment ==="
echo ""

# Create public directory if it doesn't exist
mkdir -p public

# Remove old public directory contents
rm -rf public/*

# Copy build/web to public
cp -r build/web/* public/

echo "✓ Files copied dari build/web/ ke public/"
echo ""
echo "=== Build Complete ==="
echo ""
echo "Ready for Vercel deployment!"
echo "- Build output: public/"
echo "- Deploy command: vercel --prod"
