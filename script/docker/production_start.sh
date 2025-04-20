#!/usr/bin/env bash
set -eo pipefail

# load any ENV vars from .env
if [ -f .env ]; then
  # avoid exporting commented lines
  export $(grep -v '^#' .env | xargs)
fi

echo "▶ Pulling latest images..."
docker compose pull

echo "▶ Stopping & removing old containers..."
docker compose down

echo "▶ Starting services in background..."
docker compose up -d --build --remove-orphans --force-recreate

echo "✅ All services are up!"

#docker run --env-file .env -d -p 80:3000 jonathanmeaney/supreme_ai_image_generator:latest
