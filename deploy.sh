#!/usr/bin/env bash
set -Eeuo pipefail

cd /var/www/my-wp-blog

COMPOSE=(docker compose -f docker-compose.prod.yml)

echo "==> Pull latest changes"
git pull --ff-only origin main

echo "==> Validate Compose configuration"
"${COMPOSE[@]}" config -q

echo "==> Pull WordPress image"
"${COMPOSE[@]}" pull wordpress

echo "==> Recreate WordPress container if needed"
"${COMPOSE[@]}" up -d --no-deps wordpress

echo "==> Verify WordPress container"
if [[ "$(docker inspect -f '{{.State.Running}}' wp-app-prod)" != "true" ]]; then
    echo "ERROR: WordPress container is not running" >&2
    exit 1
fi

echo "==> Verify WordPress image"
docker inspect -f 'Configured image: {{.Config.Image}}' wp-app-prod

echo "==> Verify PHP session configuration"
docker exec wp-app-prod php -i | grep -E \
    'session.upload_progress.enabled|session.serialize_handler'

echo "==> Container status"
"${COMPOSE[@]}" ps wordpress

echo "==> Deploy completed"