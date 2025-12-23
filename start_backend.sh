#!/bin/bash

# Laravel Backend Startup Script
# This script starts the Laravel backend API server on port 8000

echo "🚀 Starting Laravel Backend Server..."
echo ""

# Navigate to backend directory
cd "$(dirname "$0")/../restapi" || exit 1

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "   Copy .env.example to .env and configure it first:"
    echo "   cp .env.example .env"
    exit 1
fi

# Check if vendor directory exists
if [ ! -d vendor ]; then
    echo "⚠️  Warning: vendor directory not found."
    echo "   Installing Composer dependencies..."
    composer install
    echo ""
fi

# Check if APP_KEY is set
if ! grep -q "APP_KEY=base64:" .env; then
    echo "⚠️  Warning: APP_KEY not set."
    echo "   Generating application key..."
    php artisan key:generate
    echo ""
fi

# Clear and cache config
echo "🔧 Clearing and caching configuration..."
php artisan config:clear
php artisan cache:clear
echo ""

# Check database connection
echo "🔍 Checking database connection..."
php artisan migrate:status 2>/dev/null || {
    echo "⚠️  Warning: Database not accessible or not migrated."
    echo "   Make sure MySQL is running and database 'audit_app' exists."
    echo "   Run: php artisan migrate"
    echo ""
}

# Start the server
echo "✅ Starting Laravel development server on http://127.0.0.1:8000"
echo "   Press Ctrl+C to stop the server"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

php artisan serve --host=0.0.0.0 --port=8000

