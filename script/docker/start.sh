#!/usr/bin/env bash
set -eo pipefail

echo "Building and starting Docker containers..."
docker compose up --build

echo "Docker containers are running."
