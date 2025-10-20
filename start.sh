#!/bin/bash

# Simple start script for Hades Coturn Server
# This script handles both old and new Docker Compose syntax

set -e

echo "🚀 Starting Hades Coturn Server..."

# Detect Docker Compose command
if command -v "docker compose" &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo "📍 Using modern Docker Compose syntax"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo "📍 Using legacy Docker Compose syntax"
else
    echo "❌ Docker Compose not found. Please install Docker Compose."
    exit 1
fi

echo ""
echo "🔍 Checking SSL certificates..."
if [ -f "/etc/letsencrypt/live/cdn.hades.lt/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/cdn.hades.lt/privkey.pem" ]; then
    echo "✅ SSL certificates found!"
else
    echo "⚠️  SSL certificates not found at /etc/letsencrypt/live/cdn.hades.lt/"
    echo "   TLS will be disabled. Install certificates for full functionality."
fi

echo ""
echo "🎯 Starting containers..."
$DOCKER_COMPOSE_CMD up -d

echo ""
echo "📊 Status check:"
$DOCKER_COMPOSE_CMD ps

echo ""
echo "📋 Recent logs:"
$DOCKER_COMPOSE_CMD logs --tail=10 coturn

echo ""
echo "✅ Coturn server started successfully!"
echo ""
echo "🌐 Services available at:"
echo "   STUN/TURN: turn:cdn.hades.lt:3478"
echo "   TURN TLS:  turns:cdn.hades.lt:5349"
echo ""
echo "🔧 Useful commands:"
echo "   Check status: $DOCKER_COMPOSE_CMD ps"
echo "   View logs:    $DOCKER_COMPOSE_CMD logs -f coturn"
echo "   Stop server:  $DOCKER_COMPOSE_CMD down"
echo "   Restart:      $DOCKER_COMPOSE_CMD restart"
