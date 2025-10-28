#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo "Error: .env file not found"
  exit 1
fi

# Run Flutter with environment variables
flutter run \
  --dart-define=PARSE_APP_ID=$PARSE_APP_ID \
  --dart-define=PARSE_SERVER_URL=$PARSE_SERVER_URL \
  --dart-define=PARSE_CLIENT_KEY=$PARSE_CLIENT_KEY
