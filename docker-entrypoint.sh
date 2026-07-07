#!/bin/sh
set -e

if [ ! -f .env ]; then
    cp .env.example .env
fi

mkdir -p database

if [ ! -f database/database.sqlite ]; then
    touch database/database.sqlite
fi

if ! grep -q "^APP_KEY=base64:" .env; then
    php artisan key:generate --force
fi

php artisan migrate --force || true

php artisan config:clear
php artisan cache:clear

exec php artisan serve --host=0.0.0.0 --port=8000
